codeunit 144000 "Non-Deductible VAT Tests"
{
    // // [FEATURE] [Non Deductible VAT] [VAT]
    // 
    // --------------------------------------------------------------------------------------
    // Test Function Name                                                            TFS ID
    // --------------------------------------------------------------------------------------
    // ReverseChargeVATWithLCY                                                       212684
    // ReverseChargeVATWithLCYAndUnrealVAT                                           212684
    // ReverseChargeVATWithACY                                                       212684
    // ReverseChargeVATWithACYAndUnrealVAT                                           212684
    // HundredPctVATND                                                               208131

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryBEHelper: Codeunit "Library - BE Helper";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryJob: Codeunit "Library - Job";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        PurchStatisticsErr: Label 'Incorrect Purchase Statistics.';
        VATAmountIsEditableErr: Label '"VAT Amount" field should not be editable.';

    [Test]
    [Scope('OnPrem')]
    procedure ReverseChargeVATWithLCY()
    begin
        Initialize();
        ReverseChargeVAT(''); // pass '' for currency code
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReverseChargeVATWithLCYAndUnrealVAT()
    var
        OldUnrealVAT: Boolean;
    begin
        Initialize();
        OldUnrealVAT := UpdUnrealVATInGenLedgSetup(true);

        ReverseChargeVAT('');

        UpdUnrealVATInGenLedgSetup(OldUnrealVAT);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReverseChargeVATWithACY()
    var
        CurrencyCode: Code[10];
        OldACYCode: Code[10];
    begin
        Initialize();
        CurrencyCode := CreateCurrencyAndExchangeRate();
        OldACYCode := UpdACYInGenLedgSetup(CurrencyCode);

        ReverseChargeVAT(CurrencyCode);

        UpdACYInGenLedgSetup(OldACYCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReverseChargeVATWithACYAndUnrealVAT()
    var
        CurrencyCode: Code[10];
        OldACYCode: Code[10];
        OldUnrealVAT: Boolean;
    begin
        Initialize();
        CurrencyCode := CreateCurrencyAndExchangeRate();
        OldACYCode := UpdACYInGenLedgSetup(CurrencyCode);
        OldUnrealVAT := UpdUnrealVATInGenLedgSetup(true);

        ReverseChargeVAT(CurrencyCode);

        UpdACYInGenLedgSetup(OldACYCode);
        UpdUnrealVATInGenLedgSetup(OldUnrealVAT);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure HundredPctVATND()
    var
        GenPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        InvNo: Code[20];
        NonDedVATPct: Decimal;
    begin
        Initialize();

        LibraryERM.FindGeneralPostingSetup(GenPostingSetup);
        NonDedVATPct := 0;
        FindUpdateRevChrgVATPostingSetup(
          VATPostingSetup, GenPostingSetup."Gen. Prod. Posting Group", NonDedVATPct);
        InvNo :=
          CreatePostPurchInvWithHundredPctVATND(GenPostingSetup, VATPostingSetup);

        VerifyZeroGLEntry(InvNo, VATPostingSetup."Purchase VAT Account");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyNonDedVATOnPurchInvoiceSingleLineNormalVAT()
    var
        GLAccount: Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DocumentNo: Code[20];
        VAT: Integer;
        NonDeductibleVAT: Integer;
        AmountWithoutVAT: Decimal;
        VATAmount: Decimal;
        NonDeductibleVATAmount: Decimal;
    begin
        // http://vstfnav:8080/tfs/web/wi.aspx?pcguid=9a2ffec1-5411-458b-b788-8c4a5507644c&id=60356
        // Create a VATPostingGroup that dos not have 0% VAT.
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandInt(30));

        // Do the calculations to use it for verification later
        VAT := VATPostingSetup."VAT %";
        NonDeductibleVAT := LibraryRandom.RandInt(99);
        AmountWithoutVAT := LibraryRandom.RandIntInRange(100, 1000);
        VATAmount := Round(AmountWithoutVAT * (VAT / 100), 0.01);
        NonDeductibleVATAmount := Round(VATAmount * (NonDeductibleVAT / 100), 0.01);

        // Create a GL Account and set the '% Nondeductible VAT'
        CreateGLAccount(GLAccount, VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase, NonDeductibleVAT);

        // Create a vendor
        // Create a Purchase Invoice and POST it
        CreatePurchaseInvoiceHeader(PurchaseHeader, VATPostingSetup."VAT Bus. Posting Group");

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, "Purchase Line Type"::"G/L Account", GLAccount."No.", 1);
        PurchaseLine.Validate("Direct Unit Cost", AmountWithoutVAT);
        PurchaseLine.Modify();

        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verification
        GLEntry.SetRange("Document No.", DocumentNo);

        // 3 entries are made in the GL Entry table
        Assert.AreEqual(3, GLEntry.Count, '');

        // Line | Amount                    | VAT Amount
        // -------------------------------------------------
        // 01     "Amount Without VAT" +      "VAT Amount"
        // -      "NonDeductible VAT Amount"
        // 02      "VAT Amount"               0,00
        // 03     -("VAT Amount" +
        // -       "Amount Without VAT")      0,00
        GLEntry.FindSet();
        Assert.AreEqual(AmountWithoutVAT + NonDeductibleVATAmount, GLEntry.Amount, '');
        Assert.AreEqual(VATAmount - NonDeductibleVATAmount, GLEntry."VAT Amount", '');

        GLEntry.Next();
        Assert.AreEqual(VATAmount - NonDeductibleVATAmount, GLEntry.Amount, '');

        GLEntry.Next();
        Assert.AreEqual(-(VATAmount + AmountWithoutVAT), GLEntry.Amount, '');

        // Line | Base                        | Amount
        // -------------------------------------------------
        // 01     "Amount Without VAT" +       "VAT Amount" -
        // -      "NonDeductible VAT Amount"   "NonDeductible VAT Amount"
        VATEntry.SetRange("Document No.", DocumentNo);
        Assert.AreEqual(1, VATEntry.Count, '');
        VATEntry.FindFirst();
        Assert.AreEqual(AmountWithoutVAT + NonDeductibleVATAmount, VATEntry.Base, '');
        Assert.AreEqual(VATAmount - NonDeductibleVATAmount, VATEntry.Amount, '');
        Assert.AreEqual(NonDeductibleVATAmount, VATEntry."Non Ded. VAT Amount", '');
        Assert.AreEqual(0, VATEntry."Non Ded. Source Curr. VAT Amt.", '');

        // Verify Vendor Ledger Entries
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        Assert.AreEqual(1, VendorLedgerEntry.Count, '');
        VendorLedgerEntry.FindFirst();
        Assert.AreEqual(PurchaseHeader."Buy-from Vendor No.", VendorLedgerEntry."Vendor No.", '');
        Assert.AreEqual(-AmountWithoutVAT, VendorLedgerEntry."Purchase (LCY)", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyNonDedVATOnPurchInvoiceSingleLineReverseVAT()
    var
        GLAccount: Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DocumentNo: Code[20];
        VAT: Integer;
        NonDeductibleVAT: Integer;
        AmountWithoutVAT: Decimal;
        VATAmount: Decimal;
        NonDeductibleVATAmount: Decimal;
    begin
        // http://vstfnav:8080/tfs/web/wi.aspx?pcguid=9a2ffec1-5411-458b-b788-8c4a5507644c&id=60356
        // Create a VATPostingGroup that dos not have 0% VAT.
        CreateVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");

        // Do the calculations to use it for verification later
        VAT := VATPostingSetup."VAT %";
        NonDeductibleVAT := LibraryRandom.RandInt(99);
        AmountWithoutVAT := LibraryRandom.RandIntInRange(100, 1000);
        VATAmount := Round(AmountWithoutVAT * (VAT / 100), 0.01);
        NonDeductibleVATAmount := Round(VATAmount * (NonDeductibleVAT / 100), 0.01);

        // Create a GL Account and set the '% Nondeductible VAT'
        CreateGLAccount(GLAccount, VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase, NonDeductibleVAT);

        // Create a vendor
        // Create a Purchase Invoice and POST it
        CreatePurchaseInvoiceHeader(PurchaseHeader, VATPostingSetup."VAT Bus. Posting Group");

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, "Purchase Line Type"::"G/L Account", GLAccount."No.", 1);
        PurchaseLine.Validate("Direct Unit Cost", AmountWithoutVAT);
        PurchaseLine.Modify();

        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verification
        GLEntry.SetRange("Document No.", DocumentNo);

        // 4 entries are made in the GL Entry table
        Assert.AreEqual(4, GLEntry.Count, '');

        // Line | Amount                    | VAT Amount
        // -------------------------------------------------
        // 01     "Amount Without VAT" +      "VAT Amount"
        // -      "NonDeductible VAT Amount"
        // 02      "VAT Amount"               0,00
        // 03     -("VAT Amount")             0,00
        // 04     -("Amount Without VAT")     0,00

        GLEntry.FindSet();
        Assert.AreEqual(AmountWithoutVAT + NonDeductibleVATAmount, GLEntry.Amount, '');
        Assert.AreEqual(VATAmount - NonDeductibleVATAmount, GLEntry."VAT Amount", '');

        GLEntry.Next();
        Assert.AreEqual(VATAmount - NonDeductibleVATAmount, GLEntry.Amount, '');

        GLEntry.Next();
        Assert.AreEqual(-VATAmount, GLEntry.Amount, '');

        GLEntry.Next();
        Assert.AreEqual(-AmountWithoutVAT, GLEntry.Amount, '');

        // Line | Base                        | Amount
        // -------------------------------------------------
        // 01     "Amount Without VAT" +       "VAT Amount" -
        // -      "NonDeductible VAT Amount"   "NonDeductible VAT Amount"
        VATEntry.SetRange("Document No.", DocumentNo);
        Assert.AreEqual(1, VATEntry.Count, '');
        VATEntry.FindFirst();
        Assert.AreEqual(AmountWithoutVAT + NonDeductibleVATAmount, VATEntry.Base, '');
        Assert.AreEqual(VATAmount - NonDeductibleVATAmount, VATEntry.Amount, '');
        Assert.AreEqual(NonDeductibleVATAmount, VATEntry."Non Ded. VAT Amount", '');
        Assert.AreEqual(0, VATEntry."Non Ded. Source Curr. VAT Amt.", '');

        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        Assert.AreEqual(1, VendorLedgerEntry.Count, '');
        VendorLedgerEntry.FindFirst();
        Assert.AreEqual(PurchaseHeader."Buy-from Vendor No.", VendorLedgerEntry."Vendor No.", '');
        Assert.AreEqual(-AmountWithoutVAT, VendorLedgerEntry."Purchase (LCY)", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyNonDedVATOnPurchInvoiceMultipleLineNormalVAT()
    var
        GLAccount: Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine1: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        DocumentNo: Code[20];
        VAT: Integer;
        NonDeductibleVAT1: Integer;
        AmountWithoutVAT1: Decimal;
        AmountWithVAT1: Decimal;
        AmountWithoutVATAndDiscount1: Decimal;
        VATAmount1: Decimal;
        NonDeductibleVATAmount1: Decimal;
        LineDiscount1: Integer;
        NonDeductibleVAT2: Integer;
        AmountWithoutVAT2: Decimal;
        AmountWithVAT2: Decimal;
        VATAmount2: Decimal;
        NonDeductibleVATAmount2: Decimal;
    begin
        // http://vstfnav:8080/tfs/web/wi.aspx?pcguid=9a2ffec1-5411-458b-b788-8c4a5507644c&id=60357
        // Create a VATPostingGroup that dos not have 0% VAT.
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandInt(30));

        // Do the calculations to use it for verification later
        VAT := VATPostingSetup."VAT %";
        NonDeductibleVAT1 := 10;
        AmountWithoutVAT1 := 100;
        LineDiscount1 := 10;
        AmountWithoutVATAndDiscount1 := LibraryBEHelper.CalcPercentageChange(AmountWithoutVAT1, LineDiscount1, 0.01, false);
        VATAmount1 := LibraryBEHelper.CalcPercentage(AmountWithoutVATAndDiscount1, VAT, 0.01);
        AmountWithVAT1 := AmountWithoutVATAndDiscount1 + VATAmount1;
        NonDeductibleVATAmount1 := LibraryBEHelper.CalcPercentage(VATAmount1, NonDeductibleVAT1, 0.01);

        NonDeductibleVAT2 := LibraryRandom.RandInt(99);
        AmountWithoutVAT2 := LibraryRandom.RandIntInRange(100, 1000);
        VATAmount2 := LibraryBEHelper.CalcPercentage(AmountWithoutVAT2, VAT, 0.01);
        AmountWithVAT2 := AmountWithoutVAT2 + VATAmount2;
        NonDeductibleVATAmount2 := LibraryBEHelper.CalcPercentage(VATAmount2, NonDeductibleVAT2, 0.01);

        // Create a GL Account and set the '% Nondeductible VAT'
        CreateGLAccount(GLAccount, VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase, NonDeductibleVAT1);

        // Create a vendor
        // Create a Purchase Invoice and POST it
        CreatePurchaseInvoiceHeader(PurchaseHeader, VATPostingSetup."VAT Bus. Posting Group");

        LibraryPurchase.CreatePurchaseLine(PurchaseLine1, PurchaseHeader, "Purchase Line Type"::"G/L Account", GLAccount."No.", 1);
        PurchaseLine1.Validate("Direct Unit Cost", AmountWithoutVAT1);
        PurchaseLine1.Validate("Line Discount %", 10);
        PurchaseLine1.Modify();

        LibraryPurchase.CreatePurchaseLine(PurchaseLine2, PurchaseHeader, "Purchase Line Type"::"G/L Account", GLAccount."No.", 1);
        PurchaseLine2.Validate("Direct Unit Cost", AmountWithoutVAT2);
        PurchaseLine2.Validate("Non Deductible VAT %", NonDeductibleVAT2);
        PurchaseLine2.Validate("Allow Invoice Disc.", true);
        PurchaseLine2.Modify();

        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verification
        GLEntry.SetRange("Document No.", DocumentNo);

        // 5 entries are made in the GL Entry table
        Assert.AreEqual(5, GLEntry.Count, '');

        GLEntry.FindSet();
        Assert.AreEqual(AmountWithoutVAT2 + NonDeductibleVATAmount2, GLEntry.Amount, '');
        Assert.AreEqual(VATAmount2 - NonDeductibleVATAmount2, GLEntry."VAT Amount", '');

        GLEntry.Next();
        Assert.AreEqual(VATAmount2 - NonDeductibleVATAmount2, GLEntry.Amount, '');

        GLEntry.Next();
        Assert.AreEqual(AmountWithoutVATAndDiscount1 + NonDeductibleVATAmount1, GLEntry.Amount, '');
        Assert.AreEqual(VATAmount1 - NonDeductibleVATAmount1, GLEntry."VAT Amount", '');

        GLEntry.Next();
        Assert.AreEqual(VATAmount1 - NonDeductibleVATAmount1, GLEntry.Amount, '');

        GLEntry.Next();
        Assert.AreEqual(-(AmountWithVAT1 + AmountWithVAT2), GLEntry.Amount, '');

        // Line | Base                        | Amount
        // -------------------------------------------------
        // 01     "Amount Without VAT" +       "VAT Amount" -
        // -      "NonDeductible VAT Amount"   "NonDeductible VAT Amount"
        // 02     "Amount Without VAT" +       "VAT Amount" -
        // -      "NonDeductible VAT Amount"   "NonDeductible VAT Amount"

        VATEntry.SetRange("Document No.", DocumentNo);
        Assert.AreEqual(2, VATEntry.Count, '');
        VATEntry.FindSet();
        Assert.AreEqual(AmountWithoutVAT2 + NonDeductibleVATAmount2, VATEntry.Base, '');
        Assert.AreEqual(VATAmount2 - NonDeductibleVATAmount2, VATEntry.Amount, '');
        Assert.AreEqual(NonDeductibleVATAmount2, VATEntry."Non Ded. VAT Amount", '');

        VATEntry.Next();
        Assert.AreEqual(AmountWithoutVATAndDiscount1 + NonDeductibleVATAmount1, VATEntry.Base, '');
        Assert.AreEqual(VATAmount1 - NonDeductibleVATAmount1, VATEntry.Amount, '');
        Assert.AreEqual(NonDeductibleVATAmount1, VATEntry."Non Ded. VAT Amount", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyNonDedVATOnPurchInvoiceMultipleLineReverseVAT()
    var
        GLAccount: Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine1: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        DocumentNo: Code[20];
        VAT: Integer;
        NonDeductibleVAT1: Integer;
        AmountWithoutVAT1: Decimal;
        AmountWithoutVATAndDiscount1: Decimal;
        VATAmount1: Decimal;
        NonDeductibleVATAmount1: Decimal;
        LineDiscount1: Integer;
        NonDeductibleVAT2: Integer;
        AmountWithoutVAT2: Decimal;
        VATAmount2: Decimal;
        NonDeductibleVATAmount2: Decimal;
    begin
        // http://vstfnav:8080/tfs/web/wi.aspx?pcguid=9a2ffec1-5411-458b-b788-8c4a5507644c&id=60357
        // Create a VATPostingGroup that dos not have 0% VAT.
        CreateVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");

        // Do the calculations to use it for verification later
        VAT := VATPostingSetup."VAT %";
        NonDeductibleVAT1 := 10;
        AmountWithoutVAT1 := 100;
        LineDiscount1 := 10;
        AmountWithoutVATAndDiscount1 := LibraryBEHelper.CalcPercentageChange(AmountWithoutVAT1, LineDiscount1, 0.01, false);
        VATAmount1 := LibraryBEHelper.CalcPercentage(AmountWithoutVATAndDiscount1, VAT, 0.01);
        NonDeductibleVATAmount1 := LibraryBEHelper.CalcPercentage(VATAmount1, NonDeductibleVAT1, 0.01);

        NonDeductibleVAT2 := LibraryRandom.RandInt(99);
        AmountWithoutVAT2 := LibraryRandom.RandIntInRange(100, 1000);
        VATAmount2 := LibraryBEHelper.CalcPercentage(AmountWithoutVAT2, VAT, 0.01);
        NonDeductibleVATAmount2 := LibraryBEHelper.CalcPercentage(VATAmount2, NonDeductibleVAT2, 0.01);

        // Create a GL Account and set the '% Nondeductible VAT'
        CreateGLAccount(GLAccount, VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase, NonDeductibleVAT1);

        // Create a vendor
        // Create a Purchase Invoice and POST it
        CreatePurchaseInvoiceHeader(PurchaseHeader, VATPostingSetup."VAT Bus. Posting Group");

        LibraryPurchase.CreatePurchaseLine(PurchaseLine1, PurchaseHeader, "Purchase Line Type"::"G/L Account", GLAccount."No.", 1);
        PurchaseLine1.Validate("Direct Unit Cost", AmountWithoutVAT1);
        PurchaseLine1.Validate("Line Discount %", 10);
        PurchaseLine1.Modify();

        LibraryPurchase.CreatePurchaseLine(PurchaseLine2, PurchaseHeader, "Purchase Line Type"::"G/L Account", GLAccount."No.", 1);
        PurchaseLine2.Validate("Direct Unit Cost", AmountWithoutVAT2);
        PurchaseLine2.Validate("Non Deductible VAT %", NonDeductibleVAT2);
        PurchaseLine2.Validate("Allow Invoice Disc.", true);
        PurchaseLine2.Modify();

        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verification
        GLEntry.SetRange("Document No.", DocumentNo);

        // 7 entries are made in the GL Entry table
        Assert.AreEqual(7, GLEntry.Count, '');

        // Line | Amount                    | VAT Amount
        // -------------------------------------------------
        // 01     104,98                       9,97
        // 02       9,97                       0,00
        // 03     -19,95                       0,00
        // 04      91,89                      17,01
        // 05      17,01                       0,00
        // 06     -18,90                       0,00
        // 07    -185,00                       0,00
        GLEntry.FindSet();
        Assert.AreEqual(AmountWithoutVAT2 + NonDeductibleVATAmount2, GLEntry.Amount, '');
        Assert.AreEqual(VATAmount2 - NonDeductibleVATAmount2, GLEntry."VAT Amount", '');

        GLEntry.Next();
        Assert.AreEqual(VATAmount2 - NonDeductibleVATAmount2, GLEntry.Amount, '');

        GLEntry.Next();
        Assert.AreEqual(-VATAmount2, GLEntry.Amount, '');

        GLEntry.Next();
        Assert.AreEqual(AmountWithoutVATAndDiscount1 + NonDeductibleVATAmount1, GLEntry.Amount, '');
        Assert.AreEqual(VATAmount1 - NonDeductibleVATAmount1, GLEntry."VAT Amount", '');

        GLEntry.Next();
        Assert.AreEqual(VATAmount1 - NonDeductibleVATAmount1, GLEntry.Amount, '');

        GLEntry.Next();
        Assert.AreEqual(-VATAmount1, GLEntry.Amount, '');

        GLEntry.Next();
        Assert.AreEqual(-(AmountWithoutVATAndDiscount1 + AmountWithoutVAT2), GLEntry.Amount, '');

        // Line | Base                        | Amount
        // -------------------------------------------------
        // 01     "Amount Without VAT" +       "VAT Amount" -
        // -      "NonDeductible VAT Amount"   "NonDeductible VAT Amount"
        VATEntry.SetRange("Document No.", DocumentNo);
        Assert.AreEqual(2, VATEntry.Count, '');
        VATEntry.FindSet();
        Assert.AreEqual(AmountWithoutVAT2 + NonDeductibleVATAmount2, VATEntry.Base, '');
        Assert.AreEqual(VATAmount2 - NonDeductibleVATAmount2, VATEntry.Amount, '');
        Assert.AreEqual(NonDeductibleVATAmount2, VATEntry."Non Ded. VAT Amount", '');

        VATEntry.Next();
        Assert.AreEqual(AmountWithoutVATAndDiscount1 + NonDeductibleVATAmount1, VATEntry.Base, '');
        Assert.AreEqual(VATAmount1 - NonDeductibleVATAmount1, VATEntry.Amount, '');
        Assert.AreEqual(NonDeductibleVATAmount1, VATEntry."Non Ded. VAT Amount", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyNonDedVATOnPurchInvoiceMultipleLineReverseVATLCY()
    var
        GLAccount: Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine1: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        CurrencyCode: Code[10];
        DocumentNo: Code[20];
        VAT: Integer;
        NonDeductibleVAT1: Integer;
        AmountWithoutVAT1: Decimal;
        AmountWithoutVAT1LCY: Decimal;
        AmountWithoutVATAndDiscount1: Decimal;
        VATAmount1: Decimal;
        NonDeductibleVATAmount1: Decimal;
        LineDiscount1: Integer;
        NonDeductibleVAT2: Integer;
        AmountWithoutVAT2: Decimal;
        AmountWithoutVAT2LCY: Decimal;
        VATAmount2: Decimal;
        NonDeductibleVATAmount2: Decimal;
    begin
        // http://vstfnav:8080/tfs/web/wi.aspx?pcguid=9a2ffec1-5411-458b-b788-8c4a5507644c&id=60359
        CurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();

        // Create a VATPostingGroup that dos not have 0% VAT.
        CreateVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");

        // Do the calculations to use it for verification later
        VAT := VATPostingSetup."VAT %";
        NonDeductibleVAT1 := 10;
        AmountWithoutVAT1 := 100;
        AmountWithoutVAT1LCY := CurrencyExchangeRate.ExchangeAmount(AmountWithoutVAT1, CurrencyCode, '', WorkDate());
        LineDiscount1 := 10;
        AmountWithoutVATAndDiscount1 := LibraryBEHelper.CalcPercentageChange(AmountWithoutVAT1LCY, LineDiscount1, 0.01, false);
        VATAmount1 := LibraryBEHelper.CalcPercentage(AmountWithoutVATAndDiscount1, VAT, 0.01);
        NonDeductibleVATAmount1 := LibraryBEHelper.CalcPercentage(VATAmount1, NonDeductibleVAT1, 0.01);

        NonDeductibleVAT2 := LibraryRandom.RandInt(99);
        AmountWithoutVAT2 := LibraryRandom.RandIntInRange(100, 1000);
        AmountWithoutVAT2LCY := CurrencyExchangeRate.ExchangeAmount(AmountWithoutVAT2, CurrencyCode, '', WorkDate());
        VATAmount2 := LibraryBEHelper.CalcPercentage(AmountWithoutVAT2LCY, VAT, 0.01);
        NonDeductibleVATAmount2 := LibraryBEHelper.CalcPercentage(VATAmount2, NonDeductibleVAT2, 0.01);

        // Create a GL Account and set the '% Nondeductible VAT'
        CreateGLAccount(GLAccount, VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase, NonDeductibleVAT1);

        // Create a vendor
        // Create a Purchase Invoice and POST it
        CreatePurchaseInvoiceHeader(PurchaseHeader, VATPostingSetup."VAT Bus. Posting Group");
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Modify();

        LibraryPurchase.CreatePurchaseLine(PurchaseLine1, PurchaseHeader, "Purchase Line Type"::"G/L Account", GLAccount."No.", 1);
        PurchaseLine1.Validate("Direct Unit Cost", AmountWithoutVAT1);
        PurchaseLine1.Validate("Line Discount %", 10);
        PurchaseLine1.Modify();

        LibraryPurchase.CreatePurchaseLine(PurchaseLine2, PurchaseHeader, "Purchase Line Type"::"G/L Account", GLAccount."No.", 1);
        PurchaseLine2.Validate("Direct Unit Cost", AmountWithoutVAT2);
        PurchaseLine2.Validate("Non Deductible VAT %", NonDeductibleVAT2);
        PurchaseLine2.Validate("Allow Invoice Disc.", true);
        PurchaseLine2.Modify();

        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verification
        GLEntry.SetRange("Document No.", DocumentNo);

        // 7 entries are made in the GL Entry table
        Assert.AreEqual(7, GLEntry.Count, '');

        // Line | Amount                    | VAT Amount
        // -------------------------------------------------
        // 01     104,98                       9,97
        // 02       9,97                       0,00
        // 03     -19,95                       0,00
        // 04      91,89                      17,01
        // 05      17,01                       0,00
        // 06     -18,90                       0,00
        // 07    -185,00                       0,00
        GLEntry.FindSet();
        Assert.AreEqual(AmountWithoutVAT2LCY + NonDeductibleVATAmount2, GLEntry.Amount, '');
        Assert.AreEqual(VATAmount2 - NonDeductibleVATAmount2, GLEntry."VAT Amount", '');

        GLEntry.Next();
        Assert.AreEqual(VATAmount2 - NonDeductibleVATAmount2, GLEntry.Amount, '');

        GLEntry.Next();
        Assert.AreEqual(-VATAmount2, GLEntry.Amount, '');

        GLEntry.Next();
        Assert.AreEqual(AmountWithoutVATAndDiscount1 + NonDeductibleVATAmount1, GLEntry.Amount, '');
        Assert.AreEqual(VATAmount1 - NonDeductibleVATAmount1, GLEntry."VAT Amount", '');

        GLEntry.Next();
        Assert.AreEqual(VATAmount1 - NonDeductibleVATAmount1, GLEntry.Amount, '');

        GLEntry.Next();
        Assert.AreEqual(-VATAmount1, GLEntry.Amount, '');

        GLEntry.Next();
        Assert.AreEqual(-(AmountWithoutVATAndDiscount1 + AmountWithoutVAT2LCY), GLEntry.Amount, '');

        // Line | Base                        | Amount
        // -------------------------------------------------
        // 01     "Amount Without VAT" +       "VAT Amount" -
        // -      "NonDeductible VAT Amount"   "NonDeductible VAT Amount"
        VATEntry.SetRange("Document No.", DocumentNo);
        Assert.AreEqual(2, VATEntry.Count, '');
        VATEntry.FindSet();
        Assert.AreEqual(AmountWithoutVAT2LCY + NonDeductibleVATAmount2, VATEntry.Base, '');
        Assert.AreEqual(VATAmount2 - NonDeductibleVATAmount2, VATEntry.Amount, '');
        Assert.AreEqual(NonDeductibleVATAmount2, VATEntry."Non Ded. VAT Amount", '');

        VATEntry.Next();
        Assert.AreEqual(AmountWithoutVATAndDiscount1 + NonDeductibleVATAmount1, VATEntry.Base, '');
        Assert.AreEqual(VATAmount1 - NonDeductibleVATAmount1, VATEntry.Amount, '');
        Assert.AreEqual(NonDeductibleVATAmount1, VATEntry."Non Ded. VAT Amount", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyNonDedVATOnPurchCreditMemoSingleLineNormalVAT()
    var
        GLAccount: Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DocumentNo: Code[20];
        VAT: Integer;
        NonDeductibleVAT: Integer;
        AmountWithoutVAT: Decimal;
        VATAmount: Decimal;
        NonDeductibleVATAmount: Decimal;
    begin
        // http://vstfnav:8080/tfs/web/wi.aspx?pcguid=9a2ffec1-5411-458b-b788-8c4a5507644c&id=60356
        // Create a VATPostingGroup that dos not have 0% VAT.
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandInt(30));

        // Do the calculations to use it for verification later
        VAT := VATPostingSetup."VAT %";
        NonDeductibleVAT := LibraryRandom.RandInt(99);
        AmountWithoutVAT := LibraryRandom.RandIntInRange(100, 1000);
        VATAmount := Round(AmountWithoutVAT * (VAT / 100), 0.01);
        NonDeductibleVATAmount := Round(VATAmount * (NonDeductibleVAT / 100), 0.01);

        // Create a GL Account and set the '% Nondeductible VAT'
        CreateGLAccount(GLAccount, VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase, NonDeductibleVAT);

        // Create a vendor
        // Create a Purchase Invoice and POST it
        CreatePurchaseCrMemoHeader(PurchaseHeader, VATPostingSetup."VAT Bus. Posting Group");

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, "Purchase Line Type"::"G/L Account", GLAccount."No.", 1);
        PurchaseLine.Validate("Direct Unit Cost", AmountWithoutVAT);
        PurchaseLine.Modify();

        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verification
        GLEntry.SetRange("Document No.", DocumentNo);

        // 3 entries are made in the GL Entry table
        Assert.AreEqual(3, GLEntry.Count, '');

        // Line | Amount                    | VAT Amount
        // -------------------------------------------------
        // 01     "Amount Without VAT" +      "VAT Amount"
        // -      "NonDeductible VAT Amount"
        // 02      "VAT Amount"               0,00
        // 03     -("VAT Amount" +
        // -       "Amount Without VAT")      0,00
        GLEntry.FindSet();
        Assert.AreEqual(-(AmountWithoutVAT + NonDeductibleVATAmount), GLEntry.Amount, '');
        Assert.AreEqual(-(VATAmount - NonDeductibleVATAmount), GLEntry."VAT Amount", '');

        GLEntry.Next();
        Assert.AreEqual(-(VATAmount - NonDeductibleVATAmount), GLEntry.Amount, '');

        GLEntry.Next();
        Assert.AreEqual(VATAmount + AmountWithoutVAT, GLEntry.Amount, '');

        // Line | Base                        | Amount
        // -------------------------------------------------
        // 01     "Amount Without VAT" +       "VAT Amount" -
        // -      "NonDeductible VAT Amount"   "NonDeductible VAT Amount"
        VATEntry.SetRange("Document No.", DocumentNo);
        Assert.AreEqual(1, VATEntry.Count, '');
        VATEntry.FindFirst();
        Assert.AreEqual(-(AmountWithoutVAT + NonDeductibleVATAmount), VATEntry.Base, '');
        Assert.AreEqual(-(VATAmount - NonDeductibleVATAmount), VATEntry.Amount, '');
        Assert.AreEqual(-NonDeductibleVATAmount, VATEntry."Non Ded. VAT Amount", '');

        // Verify Vendor Ledger Entries
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        Assert.AreEqual(1, VendorLedgerEntry.Count, '');
        VendorLedgerEntry.FindFirst();
        Assert.AreEqual(PurchaseHeader."Buy-from Vendor No.", VendorLedgerEntry."Vendor No.", '');
        Assert.AreEqual(AmountWithoutVAT, VendorLedgerEntry."Purchase (LCY)", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckVATAmountOnPurchInvoiceWithReverseVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLineReverseCharge: Record "Purchase Line";
        PurchaseLineNormalVAT: Record "Purchase Line";
        VATPostingSetupReverseChargeVAT: Record "VAT Posting Setup";
        PurchaseInvoiceStatistics: TestPage "Purchase Invoice Statistics";
        DocumentNo: Code[20];
        LoweredVATReverseCharge: Decimal;
        LoweredVATNormalVAT: Decimal;
    begin
        // [FEATURE] [Reverse Charge VAT] [Purchase Invoice]
        // [SCENARIO 363018] If there is discount according to Payment Terms, it should be used while calculating Reverse Charge VAT

        // [GIVEN] Purchase Invoice Header for new Vendor with 2% VAT Base Discount
        CreatePurchHeaderWithVATBaseDisc(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);

        // [GIVEN] Purchase Invoice Line for G/L Account with 19% Reverse Charge VAT and "Direct unit Cost" = 1000
        CreatePurchaseLineWithVATType(
          PurchaseLineReverseCharge, PurchaseHeader,
          PurchaseLineReverseCharge."VAT Calculation Type"::"Reverse Charge VAT");

        VATPostingSetupReverseChargeVAT.Get(
          PurchaseLineReverseCharge."VAT Bus. Posting Group", PurchaseLineReverseCharge."VAT Prod. Posting Group");

        // [GIVEN] Purchase Invoice Line for G/L Account with 21% Normal VAT and "Direct unit Cost" = 1000
        CreatePurchaseLineWithVATType(
          PurchaseLineNormalVAT, PurchaseHeader,
          PurchaseLineNormalVAT."VAT Calculation Type"::"Normal VAT");

        // [GIVEN] Expected lowered VAT amount for Purchase Line with Reverse Charge VAT, which is calculated according to discount: 1000*(1-0,02) * 0,19 = 186,2
        LoweredVATReverseCharge := GetLoweredVATAmount(
            PurchaseLineReverseCharge."Direct Unit Cost", PurchaseHeader."VAT Base Discount %", VATPostingSetupReverseChargeVAT."VAT %");

        // [GIVEN] Expected lowered VAT amount for Purchase Line with Normal VAT, which is calculated according to discount: 1000*(1-0,02) * 0,21 = 205,8
        LoweredVATNormalVAT := GetLoweredVATAmount(
            PurchaseLineNormalVAT."Direct Unit Cost", PurchaseHeader."VAT Base Discount %", PurchaseLineNormalVAT."VAT %");

        // [WHEN] Post Purchase Invoice
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Header of Statistics page contains VAT only from line with Normal VAT
        PurchaseInvoiceStatistics.Trap();
        OpenPurchInvStatistics(DocumentNo);

        PurchaseInvoiceStatistics.VATAmount.AssertEquals(
          PurchaseLineNormalVAT."Amount Including VAT" - PurchaseLineNormalVAT."Line Amount");
        PurchaseInvoiceStatistics.AmountInclVAT.AssertEquals(
          PurchaseLineNormalVAT."Amount Including VAT" + PurchaseLineReverseCharge.Amount);

        // [THEN] Line of Statistics page considering info about the Line with Reverse Charge VAT has "VAT %" = 0, "VAT Amount" = 0 and
        // [THEN] "Amount Including VAT" = "Amount"
        PurchaseInvoiceStatistics.SubForm.First();
        VerifyPurchInvStatLine(PurchaseInvoiceStatistics, 0, 0, PurchaseLineReverseCharge.Amount);
        // BUG: 409219
        PurchaseInvoiceStatistics.SubForm."VAT Base (Lowered)".AssertEquals(
          GetLoweredVATBase(PurchaseLineReverseCharge."Direct Unit Cost", PurchaseHeader."VAT Base Discount %"));

        // [THEN] Line of Statistics page considering info about the Line with Normal VAT has "VAT %", "VAT Amount", "Amount Including VAT"
        // [THEN] as they are in Purchase Line
        PurchaseInvoiceStatistics.SubForm.Next();
        VerifyPurchInvStatLine(
          PurchaseInvoiceStatistics, PurchaseLineNormalVAT."VAT %",
          PurchaseLineNormalVAT."Amount Including VAT" - PurchaseLineNormalVAT."Line Amount",
          PurchaseLineNormalVAT."Amount Including VAT");
        // BUG: 409219
        PurchaseInvoiceStatistics.SubForm."VAT Base (Lowered)".AssertEquals(
          GetLoweredVATBase(PurchaseLineNormalVAT."Direct Unit Cost", PurchaseHeader."VAT Base Discount %"));

        PurchaseInvoiceStatistics.Close();

        // [THEN] 2 entry is created in VAT Entry table
        // [THEN] 1st VAT Entry is of Normal type and VAT amount is calculated according to discount: 205,8
        // [THEN] 2nd VAT Entry is of Reverse charge type and VAT amount is calculated according to discount: 186,2
        VerifyVATEntriesWithReverseCharge(
          PurchaseHeader."Document Type"::Invoice, DocumentNo, LoweredVATReverseCharge, LoweredVATNormalVAT,
          GetLoweredVATBase(PurchaseLineReverseCharge."Direct Unit Cost", PurchaseHeader."VAT Base Discount %"),
          GetLoweredVATBase(PurchaseLineNormalVAT."Direct Unit Cost", PurchaseHeader."VAT Base Discount %"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckVATAmountOnPurchCrMemoWithReverseVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLineReverseCharge: Record "Purchase Line";
        PurchaseLineNormalVAT: Record "Purchase Line";
        VATPostingSetupReverseChargeVAT: Record "VAT Posting Setup";
        PurchaseCrMemoStatistics: TestPage "Purch. Credit Memo Statistics";
        DocumentNo: Code[20];
        LoweredVATReverseCharge: Decimal;
        LoweredVATNormalVAT: Decimal;
    begin
        // [FEATURE] [Reverse Charge VAT] [Purchase Credit Memo]
        // [SCENARIO 363018] Purchase Credit Memo Statistics should be shown as if VAT % is 0 in case of Reverse Charge VAT

        // [GIVEN] Purchase Credit Memo Header for new Vendor with 2% VAT Base Discount
        CreatePurchHeaderWithVATBaseDisc(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo");

        // [GIVEN] Purchase Credit Memo Line for G/L Account with 19% Reverse Charge VAT and "Direct unit Cost" = 1000
        CreatePurchaseLineWithVATType(
          PurchaseLineReverseCharge, PurchaseHeader,
          PurchaseLineReverseCharge."VAT Calculation Type"::"Reverse Charge VAT");

        // [GIVEN] Purchase Credit Memo Line for G/L Account with 21% Normal VAT and "Direct unit Cost" = 1000
        CreatePurchaseLineWithVATType(
          PurchaseLineNormalVAT, PurchaseHeader,
          PurchaseLineNormalVAT."VAT Calculation Type"::"Normal VAT");

        VATPostingSetupReverseChargeVAT.Get(
          PurchaseLineReverseCharge."VAT Bus. Posting Group", PurchaseLineReverseCharge."VAT Prod. Posting Group");

        // [GIVEN] Expected lowered VAT amount for Purchase Credit Memo Line with Reverse Charge VAT, which is calculated according to discount: 1000*(1-0,02) * 0,19 = 186,2
        LoweredVATReverseCharge := GetLoweredVATAmount(
            PurchaseLineReverseCharge."Direct Unit Cost", PurchaseHeader."VAT Base Discount %", VATPostingSetupReverseChargeVAT."VAT %");

        // [GIVEN] Expected lowered VAT amount for Purchase Credit Memo Line with Normal VAT, which is calculated according to discount: 1000*(1-0,02) * 0,21 = 205,8
        LoweredVATNormalVAT := GetLoweredVATAmount(
            PurchaseLineNormalVAT."Direct Unit Cost", PurchaseHeader."VAT Base Discount %", PurchaseLineNormalVAT."VAT %");

        // [WHEN] Post Purchase Credit Memo
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Header of Statistics page contains VAT only from line with Normal VAT
        PurchaseCrMemoStatistics.Trap();
        OpenPurchCrMemoStatistics(DocumentNo);

        PurchaseCrMemoStatistics.VATAmount.AssertEquals(
          PurchaseLineNormalVAT."Amount Including VAT" - PurchaseLineNormalVAT."Line Amount");
        PurchaseCrMemoStatistics.AmountInclVAT.AssertEquals(
          PurchaseLineNormalVAT."Amount Including VAT" + PurchaseLineReverseCharge.Amount);

        // [THEN] Line of Statistics page considering info about the Line with Reverse Charge VAT has "VAT %" = 0, "VAT Amount" = 0 and
        // [THEN] "Amount Including VAT" = "Amount"
        PurchaseCrMemoStatistics.SubForm.First();
        VerifyPurchCrMemoStatLine(PurchaseCrMemoStatistics, 0, 0, PurchaseLineReverseCharge.Amount);
        // BUG: 409219
        PurchaseCrMemoStatistics.SubForm."VAT Base (Lowered)".AssertEquals(
          GetLoweredVATBase(PurchaseLineReverseCharge."Direct Unit Cost", PurchaseHeader."VAT Base Discount %"));

        // [THEN] Line of Statistics page considering info about the Line with Normal VAT has "VAT %", "VAT Amount", "Amount Including VAT"
        // [THEN] as they are in Purchase Credit Memo Line
        PurchaseCrMemoStatistics.SubForm.Next();
        VerifyPurchCrMemoStatLine(
          PurchaseCrMemoStatistics, PurchaseLineNormalVAT."VAT %",
          PurchaseLineNormalVAT."Amount Including VAT" - PurchaseLineNormalVAT."Line Amount",
          PurchaseLineNormalVAT."Amount Including VAT");
        // BUG: 409219
        PurchaseCrMemoStatistics.SubForm."VAT Base (Lowered)".AssertEquals(
          GetLoweredVATBase(PurchaseLineNormalVAT."Direct Unit Cost", PurchaseHeader."VAT Base Discount %"));

        PurchaseCrMemoStatistics.Close();

        // [THEN] 2 entry is created in VAT Entry table
        // [THEN] 1st VAT Entry is of Normal type and VAT amount is calculated according to discount: 205,8
        // [THEN] 2nd VAT Entry is of Reverse charge type and VAT amount is calculated according to discount: 186,2
        VerifyVATEntriesWithReverseCharge(
          PurchaseHeader."Document Type"::"Credit Memo", DocumentNo, -LoweredVATReverseCharge, -LoweredVATNormalVAT,
          -GetLoweredVATBase(PurchaseLineReverseCharge."Direct Unit Cost", PurchaseHeader."VAT Base Discount %"),
          -GetLoweredVATBase(PurchaseLineNormalVAT."Direct Unit Cost", PurchaseHeader."VAT Base Discount %"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckUsingVATForReverseCharge()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        VATPct: Integer;
    begin
        // [FEATURE] [Reverse Charge VAT] [UT] [Purchase] [Posting]
        // [SCENARIO 363796] Reverse Charge VAT % should be taken into account while Purchase posting

        // [GIVEN] Purchase Invoice Header for new Vendor with 2% VAT Base Discount
        CreatePurchHeaderWithVATBaseDisc(PurchHeader, PurchHeader."Document Type"::Invoice);

        // [GIVEN] Purchase Invoice Line for G/L Account with 19% Reverse Charge VAT and "Direct unit Cost" = 1000
        CreatePurchaseLineWithVATType(
          PurchLine, PurchHeader, PurchLine."VAT Calculation Type"::"Reverse Charge VAT");
        VATPct := PurchLine."VAT %";

        // [WHEN] Calling CalcVATAmountLines function for Purchase Line as it is being done during posting
        PurchLine.CalcVATAmountLines(1, PurchHeader, PurchLine, TempVATAmountLine);

        // [THEN] TempVATAmountLine created for Purchase contains VAT %
        Assert.AreEqual(VATPct, TempVATAmountLine."VAT %", TempVATAmountLine.FieldCaption("VAT %"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckUsingNoVATForReverseCharge()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        TempVATAmountLine: Record "VAT Amount Line" temporary;
    begin
        // [FEATURE] [Reverse Charge VAT] [UT] [Purchase] [Posting]
        // [SCENARIO 363796] Reverse Charge VAT % should not be shown in Purchase statistics and reports

        // [GIVEN] Purchase Invoice Header for new Vendor with 2% VAT Base Discount
        CreatePurchHeaderWithVATBaseDisc(PurchHeader, PurchHeader."Document Type"::Invoice);

        // [GIVEN] Purchase Invoice Line for G/L Account with 19% Reverse Charge VAT and "Direct unit Cost" = 1000
        CreatePurchaseLineWithVATType(
          PurchLine, PurchHeader, PurchLine."VAT Calculation Type"::"Reverse Charge VAT");

        // [WHEN] Calling CalcVATAmountLines function for Purchase Line as it is being done while getting statistics and reporting
        PurchLine.CalcVATAmountLines(1, PurchHeader, PurchLine, TempVATAmountLine);

        // [THEN] TempVATAmountLine created for Purchase contains 0 VAT %
        TempVATAmountLine.TestField("VAT %", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyAmountsOnPurchInvoiceWithReverseVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvLine: Record "Purch. Inv. Line";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Reverse Charge VAT]
        // [SCENARIO 374936] If Purchase Invoice has Reverce Charge VAT Calculation Type, its "Amount Including VAT" should equals "Amount"
        Initialize();

        // [GIVEN] Purchase Invoice Header for new Vendor with 2% VAT Base Discount
        // [GIVEN] Purchase Invoice Line for G/L Account with 19% Reverse Charge VAT and "Direct unit Cost" = 1000
        CreatePurchaseOrderWithDiscountAndReverseChargeVAT(PurchaseHeader, PurchaseLine);

        // [WHEN] Post Purchase Invoice
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] In posted invoice "Amount Including VAT" equals to "Amount"
        PurchInvLine.SetFilter("Document No.", DocumentNo);
        PurchInvLine.FindFirst();
        PurchInvLine.TestField("Amount Including VAT", PurchInvLine.Amount);
        // [THEN] In invoice line "Outstanding Amount" equals to "Amount"
        PurchaseLine.TestField("Outstanding Amount", PurchInvLine.Amount);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseStatisticsModalPageHandler')]
    [Scope('OnPrem')]
    procedure StatsForNonDedVATOnPurchInvMultipleLineNormalVATBeforePosting()
    var
        GLAccount: Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine1: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseInvoice: TestPage "Purchase Invoice";
        NonDeductibleVATPct: array[2] of Integer;
        AmountWithoutVAT: array[2] of Decimal;
        AmountWithoutVATAndDiscount1: Decimal;
        VATAmount: array[2] of Decimal;
        NonDeductibleVATAmount: array[2] of Decimal;
        LineDiscount1: Integer;
    begin
        // [FEATURE] [Normal VAT] [Statistics] [Purchase Invoice]
        // [SCENARIO 375454] While creating Purchase Invoice, Non Deductible VAT should be shown in statistics as will be posted.

        Initialize();

        // [GIVEN] VATPostingGroup with 10% Normal VAT
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandInt(30));

        // Amounts to be used during setup and verification
        SetupAmountsForNonVATPurchaseStat(
          NonDeductibleVATPct, AmountWithoutVAT, AmountWithoutVATAndDiscount1, VATAmount, NonDeductibleVATAmount, LineDiscount1,
          VATPostingSetup."VAT %");

        // Enqueue amounts to use them in PurchaseStatisticsModalPageHandler
        EnqueueAmountsForPurchStatisticsHandler(
          NonDeductibleVATAmount, VATAmount, AmountWithoutVATAndDiscount1, AmountWithoutVAT[2], true);

        // [GIVEN] G/L Account with 30 "% Nondeductible VAT"
        CreateGLAccount(GLAccount, VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase, NonDeductibleVATPct[1]);

        // [GIVEN] Purchase Invoice having two Lines
        CreatePurchaseInvoiceHeader(PurchaseHeader, VATPostingSetup."VAT Bus. Posting Group");

        // [GIVEN] 1st Purchase Line having Amount 1000 (after discount) and 20% non deductible VAT
        LibraryPurchase.CreatePurchaseLine(PurchaseLine1, PurchaseHeader, PurchaseLine1.Type::"G/L Account", GLAccount."No.", 1);
        PurchaseLine1.Validate("Direct Unit Cost", AmountWithoutVAT[1]);
        PurchaseLine1.Validate("Line Discount %", LineDiscount1);
        PurchaseLine1.Modify();

        // [GIVEN] 2nd Purchase Line having Amount 2000 and 30 % non deductible VAT
        LibraryPurchase.CreatePurchaseLine(PurchaseLine2, PurchaseHeader, PurchaseLine2.Type::"G/L Account", GLAccount."No.", 1);
        PurchaseLine2.Validate("Direct Unit Cost", AmountWithoutVAT[2]);
        PurchaseLine2.Validate("Non Deductible VAT %", NonDeductibleVATPct[2]);
        PurchaseLine2.Validate("Allow Invoice Disc.", true);
        PurchaseLine2.Modify();

        // [WHEN] Check Statistics in Purhase Invoice page
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchaseHeader);
        PurchaseInvoice.Statistics.Invoke();

        // Following checks are performed in PurchaseStatisticsModalPageHandler handler
        // [THEN] "Total" on Statistics page contains sum of Amounts (1000 + 2000) and non deductible VATs (1000*0.1*0.2 + 2000*0.1*0.3) = 3080
        // [THEN] "VAT Amount" on Statistics page contains lines' VATs without non deductible part (100 + 200) - (20 + 60) = 220
        // [THEN] "Total Incl. VAT" on Statistics page contains sum of Amounts and VATs (1000 + 2000) + (100 + 200) = 3300
        // [THEN] "VAT Base (Lowered)" field of VAT Line on Statistics page = 3080
        // [THEN] "VAT Amount" field of VAT Line on Statistics page = 220
        // [THEN] "Amount Including VAT" field of VAT Line on Statistics page = 3300
        // [THEN] "Line Amount" field of VAT Line on Statistics page = 3300

        // [THEN] "Total Amount Excl. VAT" = 3080
        PurchaseInvoice.PurchLines."Total Amount Excl. VAT".AssertEquals(
          AmountWithoutVATAndDiscount1 + AmountWithoutVAT[2] + NonDeductibleVATAmount[1] + NonDeductibleVATAmount[2]);

        // [THEN] "VAT Amount" = 220
        PurchaseInvoice.PurchLines."Total VAT Amount".AssertEquals(
          VATAmount[1] + VATAmount[2] - NonDeductibleVATAmount[1] - NonDeductibleVATAmount[2]);

        // [THEN] "Total Amount Incl. VAT" = 3300
        PurchaseInvoice.PurchLines."Total Amount Incl. VAT".AssertEquals(
          AmountWithoutVATAndDiscount1 + AmountWithoutVAT[2] + VATAmount[1] + VATAmount[2]);
    end;
#endif

    [Test]
    [HandlerFunctions('PurchaseStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure PurchStatsForNonDedVATOnPurchInvMultipleLineNormalVATBeforePosting()
    var
        GLAccount: Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine1: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseInvoice: TestPage "Purchase Invoice";
        NonDeductibleVATPct: array[2] of Integer;
        AmountWithoutVAT: array[2] of Decimal;
        AmountWithoutVATAndDiscount1: Decimal;
        VATAmount: array[2] of Decimal;
        NonDeductibleVATAmount: array[2] of Decimal;
        LineDiscount1: Integer;
    begin
        // [FEATURE] [Normal VAT] [Statistics] [Purchase Invoice]
        // [SCENARIO 375454] While creating Purchase Invoice, Non Deductible VAT should be shown in statistics as will be posted.

        Initialize();

        // [GIVEN] VATPostingGroup with 10% Normal VAT
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandInt(30));

        // Amounts to be used during setup and verification
        SetupAmountsForNonVATPurchaseStat(
          NonDeductibleVATPct, AmountWithoutVAT, AmountWithoutVATAndDiscount1, VATAmount, NonDeductibleVATAmount, LineDiscount1,
          VATPostingSetup."VAT %");

        // Enqueue amounts to use them in PurchaseStatisticsPageHandler
        EnqueueAmountsForPurchStatisticsHandler(
          NonDeductibleVATAmount, VATAmount, AmountWithoutVATAndDiscount1, AmountWithoutVAT[2], true);

        // [GIVEN] G/L Account with 30 "% Nondeductible VAT"
        CreateGLAccount(GLAccount, VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase, NonDeductibleVATPct[1]);

        // [GIVEN] Purchase Invoice having two Lines
        CreatePurchaseInvoiceHeader(PurchaseHeader, VATPostingSetup."VAT Bus. Posting Group");

        // [GIVEN] 1st Purchase Line having Amount 1000 (after discount) and 20% non deductible VAT
        LibraryPurchase.CreatePurchaseLine(PurchaseLine1, PurchaseHeader, PurchaseLine1.Type::"G/L Account", GLAccount."No.", 1);
        PurchaseLine1.Validate("Direct Unit Cost", AmountWithoutVAT[1]);
        PurchaseLine1.Validate("Line Discount %", LineDiscount1);
        PurchaseLine1.Modify();

        // [GIVEN] 2nd Purchase Line having Amount 2000 and 30 % non deductible VAT
        LibraryPurchase.CreatePurchaseLine(PurchaseLine2, PurchaseHeader, PurchaseLine2.Type::"G/L Account", GLAccount."No.", 1);
        PurchaseLine2.Validate("Direct Unit Cost", AmountWithoutVAT[2]);
        PurchaseLine2.Validate("Non Deductible VAT %", NonDeductibleVATPct[2]);
        PurchaseLine2.Validate("Allow Invoice Disc.", true);
        PurchaseLine2.Modify();

        // [WHEN] Check Statistics in Purhase Invoice page
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchaseHeader);
        PurchaseInvoice.PurchaseStatistics.Invoke();

        // Following checks are performed in PurchaseStatisticsPageHandler handler
        // [THEN] "Total" on Statistics page contains sum of Amounts (1000 + 2000) and non deductible VATs (1000*0.1*0.2 + 2000*0.1*0.3) = 3080
        // [THEN] "VAT Amount" on Statistics page contains lines' VATs without non deductible part (100 + 200) - (20 + 60) = 220
        // [THEN] "Total Incl. VAT" on Statistics page contains sum of Amounts and VATs (1000 + 2000) + (100 + 200) = 3300
        // [THEN] "VAT Base (Lowered)" field of VAT Line on Statistics page = 3080
        // [THEN] "VAT Amount" field of VAT Line on Statistics page = 220
        // [THEN] "Amount Including VAT" field of VAT Line on Statistics page = 3300
        // [THEN] "Line Amount" field of VAT Line on Statistics page = 3300

        // [THEN] "Total Amount Excl. VAT" = 3080
        PurchaseInvoice.PurchLines."Total Amount Excl. VAT".AssertEquals(
          AmountWithoutVATAndDiscount1 + AmountWithoutVAT[2] + NonDeductibleVATAmount[1] + NonDeductibleVATAmount[2]);

        // [THEN] "VAT Amount" = 220
        PurchaseInvoice.PurchLines."Total VAT Amount".AssertEquals(
          VATAmount[1] + VATAmount[2] - NonDeductibleVATAmount[1] - NonDeductibleVATAmount[2]);

        // [THEN] "Total Amount Incl. VAT" = 3300
        PurchaseInvoice.PurchLines."Total Amount Incl. VAT".AssertEquals(
          AmountWithoutVATAndDiscount1 + AmountWithoutVAT[2] + VATAmount[1] + VATAmount[2]);
    end;

    [Test]
    [HandlerFunctions('PostedPurchaseStatisticsModalPageHandler')]
    [Scope('OnPrem')]
    procedure StatsForNonDedVATOnPurchInvMultipleLineNormalVATAfterPosting()
    var
        GLAccount: Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseLine1: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
        DocumentNo: Code[20];
        NonDeductibleVATPct: array[2] of Integer;
        AmountWithoutVAT: array[2] of Decimal;
        AmountWithoutVATAndDiscount1: Decimal;
        VATAmount: array[2] of Decimal;
        NonDeductibleVATAmount: array[2] of Decimal;
        LineDiscount1: Integer;
    begin
        // [FEATURE] [Normal VAT] [Statistics] [Posted Purchase Invoice]
        // [SCENARIO 375454] Non Deductible VAT should be shown in In Posted Purchase Invoice Statistics as it was posted.

        Initialize();

        // [GIVEN] VATPostingGroup with 10% Normal VAT
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandInt(30));

        // Amounts to be used during setup and verification
        SetupAmountsForNonVATPurchaseStat(
          NonDeductibleVATPct, AmountWithoutVAT, AmountWithoutVATAndDiscount1, VATAmount, NonDeductibleVATAmount, LineDiscount1,
          VATPostingSetup."VAT %");

        // Enqueue amounts to use them in PostedPurchaseStatisticsModalPageHandler
        EnqueueAmountsForPurchStatisticsHandler(
          NonDeductibleVATAmount, VATAmount, AmountWithoutVATAndDiscount1, AmountWithoutVAT[2], true);

        // [GIVEN] G/L Account with 30 "% Nondeductible VAT"
        CreateGLAccount(GLAccount, VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase, NonDeductibleVATPct[1]);

        // [GIVEN] Purchase Invoice having two Lines
        CreatePurchaseInvoiceHeader(PurchaseHeader, VATPostingSetup."VAT Bus. Posting Group");

        // [GIVEN] 1st Purchase Line having Amount 1000 (after discount) and 20% non deductible VAT
        LibraryPurchase.CreatePurchaseLine(PurchaseLine1, PurchaseHeader, PurchaseLine1.Type::"G/L Account", GLAccount."No.", 1);
        PurchaseLine1.Validate("Direct Unit Cost", AmountWithoutVAT[1]);
        PurchaseLine1.Validate("Line Discount %", LineDiscount1);
        PurchaseLine1.Modify();

        // [GIVEN] 2nd Purchase Line having Amount 2000 and 30 % non deductible VAT
        LibraryPurchase.CreatePurchaseLine(PurchaseLine2, PurchaseHeader, PurchaseLine2.Type::"G/L Account", GLAccount."No.", 1);
        PurchaseLine2.Validate("Direct Unit Cost", AmountWithoutVAT[2]);
        PurchaseLine2.Validate("Non Deductible VAT %", NonDeductibleVATPct[2]);
        PurchaseLine2.Validate("Allow Invoice Disc.", true);
        PurchaseLine2.Modify();

        // [GIVEN] Purchase Invoice is posted
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        PurchInvHeader.Get(DocumentNo);

        // [WHEN] Check Statistics in Posted Purhase Invoice page
        PostedPurchaseInvoice.OpenEdit();
        PostedPurchaseInvoice.GotoRecord(PurchInvHeader);
        PostedPurchaseInvoice.Statistics.Invoke();

        // Following checks are performed in PostedPurchaseStatisticsModalPageHandler handler
        // [THEN] "Total" on Statistics page contains sum of Amounts (1000 + 2000) and non deductible VATs (1000*0.1*0.2 + 2000*0.1*0.3) = 3080
        // [THEN] "VAT Amount" on Statistics page contains lines' VATs without non deductible part (100 + 200) - (20 + 60) = 220
        // [THEN] "Total Incl. VAT" on Statistics page contains sum of Amounts and VATs (1000 + 2000) + (100 + 200) = 3300
        // [THEN] "VAT Base (Lowered)" field of VAT Line on Statistics page = 3080
        // [THEN] VAT Amount Line on Statistics page, where "VAT Amount" = 220, "Amount Including VAT" = 3300, "Line Amount" = 3300.

        // [THEN] "Total Amount Excl. VAT" = 3080
        PostedPurchaseInvoice.PurchInvLines."Total Amount Excl. VAT".AssertEquals(
          AmountWithoutVATAndDiscount1 + AmountWithoutVAT[2] + NonDeductibleVATAmount[1] + NonDeductibleVATAmount[2]);

        // [THEN] "VAT Amount" = 220
        PostedPurchaseInvoice.PurchInvLines."Total VAT Amount".AssertEquals(
          VATAmount[1] + VATAmount[2] - NonDeductibleVATAmount[1] - NonDeductibleVATAmount[2]);

        // [THEN] "Total Amount Incl. VAT" = 3300
        PostedPurchaseInvoice.PurchInvLines."Total Amount Incl. VAT".AssertEquals(
          AmountWithoutVATAndDiscount1 + AmountWithoutVAT[2] + VATAmount[1] + VATAmount[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseStatisticsForLineWithDiescriptionOnly()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoiceStatistics: TestPage "Purchase Invoice Statistics";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Statistics]
        // [SCENARIO 377239] Statistics for posted Purchase Invoice must be shown even if Purchase Invoice includes the line with only the "Description" filled in

        Initialize();

        // [GIVEN] The 1st line of Purchase Invoice having only the "Description" filled in
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        PurchaseLine.Init();
        PurchaseLine.Description := CopyStr(LibraryUtility.GenerateRandomText(10), 1, 10);
        PurchaseLine.Insert();

        // [GIVEN] The 2nd line of Purchase Invoice having No. and Amount filled in
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), 1);

        // [GIVEN] Purchase Invoice is posted
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [WHEN] Openning Statistics for Posted Purchase Invoice
        PurchInvHeader.Get(DocumentNo);
        PurchaseInvoiceStatistics.Trap();
        PAGE.Run(PAGE::"Purchase Invoice Statistics", PurchInvHeader);

        // [THEN] Statistics page is opened and the line's "Amount Including VAT" value is equal to "Amount" in Purchase Header
        Assert.AreEqual(PurchInvHeader.Amount, PurchaseInvoiceStatistics.AmountInclVAT.AsDecimal(), PurchStatisticsErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATDifferenceNotAllowedInCaseOfNonDeductibleVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseStatistics: TestPage "Purchase Statistics";
    begin
        // [FEATURE] [Purchase] [Statistics]
        // [SCENARIO 377347] If Non Deductible VAT % is specified in Purchase Line, then manual change of VAT Amount in pre-posting Statistics should not be allowed

        Initialize();

        // [GIVEN] 1st Purchase Invoice Line with 90 % Non Deductible VAT
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(100));
        PurchaseLine.Validate("Non Deductible VAT %", LibraryRandom.RandInt(90));
        PurchaseLine.Modify(true);

        // [GIVEN] 2nd Purchase Invoice Line without Non Deductible VAT
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(100));
        PurchaseLine.Modify(true);

        // [WHEN] Open Purchase Invoice Statistics
        PurchaseStatistics.Trap();
        PAGE.Run(PAGE::"Purchase Statistics", PurchaseHeader);

        // [THEN] "VAT Amount" field is not editable in all lines
        Assert.IsFalse(PurchaseStatistics.SubForm."VAT Amount".Editable(), VATAmountIsEditableErr);
        PurchaseStatistics.SubForm.Next();
        Assert.IsFalse(PurchaseStatistics.SubForm."VAT Amount".Editable(), VATAmountIsEditableErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NonDedVATOnPurchInvoiceMultipleItemLineReverseChargeVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        VATEntry: Record "VAT Entry";
        InvoiceNo: Code[20];
        VATAmount: array[2] of Decimal;
        VATEntryBase: array[2] of Decimal;
        VATEntryAmount: array[2] of Decimal;
        VATEntryNDAmount: array[2] of Decimal;
        i: Integer;
    begin
        // [FEATURE] [Reverse Charge VAT] [Item]
        // [SCENARIO 380267] VAT Entry has summarized "Non Ded. VAT Amount" after posting mutliple Item line Purchase Invoice with Reverse Charge VAT
        Initialize();

        // [GIVEN] Vendor with Reverse Charge VAT setup and VAT% = 21.
        CreateVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        // [GIVEN] Purchase Invoice with two Item lines:
        CreatePurchaseInvoiceHeader(PurchaseHeader, VATPostingSetup."VAT Bus. Posting Group");
        // [GIVEN] Line1: Amount = 100, "Non Deductible VAT %" = 75
        CreatePurchaseItemLine(PurchaseLine[1], PurchaseHeader, VATPostingSetup);
        // [GIVEN] Line2: Amount = 100, "Non Deductible VAT %" = 75
        CreatePurchaseItemLine(PurchaseLine[2], PurchaseHeader, VATPostingSetup);

        // [WHEN] Post Purchase Invoice
        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Invoice has been posted and VAT Entry has been created:
        // [THEN] Base = 231.50; Amount = 10.5; "Non Ded. VAT Amount" = 31.50
        for i := 1 to 2 do begin
            VATAmount[i] := Round(PurchaseLine[i].Amount * VATPostingSetup."VAT %" / 100);
            VATEntryNDAmount[i] := Round(VATAmount[i] * PurchaseLine[i]."Non Deductible VAT %" / 100);
            VATEntryBase[i] := PurchaseLine[i].Amount + VATEntryNDAmount[i];
            VATEntryAmount[i] := VATAmount[i] - VATEntryNDAmount[i];
        end;
        FindVATEntry(VATEntry, PurchaseHeader."Buy-from Vendor No.", InvoiceNo);
        Assert.AreEqual(VATEntryBase[1] + VATEntryBase[2], VATEntry.Base, VATEntry.FieldCaption(Base));
        Assert.AreEqual(VATEntryAmount[1] + VATEntryAmount[2], VATEntry.Amount, VATEntry.FieldCaption(Amount));
        Assert.AreEqual(
          VATEntryNDAmount[1] + VATEntryNDAmount[2], VATEntry."Non Ded. VAT Amount", VATEntry.FieldCaption("Non Ded. VAT Amount"));
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseStatisticsModalPageHandler')]
    [Scope('OnPrem')]
    procedure StatsForOnePurchInvoiceWhenAnotherInvoiceHasNonDedVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
        VATPostingSetup2: Record "VAT Posting Setup";
        PurchaseInvoice: TestPage "Purchase Invoice";
        NonDeductibleVATPct: array[2] of Integer;
        AmountWithoutVAT: array[2] of Decimal;
        VATAmount: array[2] of Decimal;
        NonDeductibleVATAmount: array[2] of Decimal;
        AmountWithoutVATAndDiscount: Decimal;
    begin
        // [FEATURE] [Normal VAT] [Statistics] [Purchase Invoice]
        // [SCENARIO 381042] Show Statistics for Purchase Invoice when another Invoice has Non-Deductible VAT.
        Initialize();

        // [GIVEN] Purchase Invoice "PI" with "Non Deductible VAT" = 0, VAT% = 21, "Amount Excl. VAT" = 100.
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandInt(30));
        SetupAmountsForNonVATPurchaseStatOneLine(
          NonDeductibleVATPct, AmountWithoutVAT, AmountWithoutVATAndDiscount, VATAmount, NonDeductibleVATAmount, 0, 0,
          VATPostingSetup."VAT %");
        CreatePurchInvoiceWithNonDeductibleVAT(
          PurchaseHeader, VATPostingSetup, AmountWithoutVAT[1], NonDeductibleVATPct[1]);

        // [GIVEN] Second Purchase Invoice with non-deductible VAT and different "VAT Prod. Posting Group"
        CreateCopyVATPostingSetup(VATPostingSetup2, VATPostingSetup);
        CreatePurchInvoiceWithNonDeductibleVAT(
          PurchaseHeader2, VATPostingSetup2, LibraryRandom.RandDecInRange(100, 200, 2), LibraryRandom.RandInt(10));

        // Enqueue amounts for PurchaseStatisticsModalPageHandler
        EnqueueAmountsForPurchStatisticsHandler(NonDeductibleVATAmount, VATAmount, AmountWithoutVAT[1], 0, true);

        // [WHEN] Open Statistics for Purchase Invoice "PI"
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchaseHeader);
        PurchaseInvoice.Statistics.Invoke();

        // Verification is done inside PurchaseStatisticsModalPageHandler
        // [THEN] General Tab has "21% VAT" = 21, "Total Incl. VAT" = 121, Purchase (LCY) = 100
        // [THEN] Lines Tab has "VAT Base (Lowered)" = 100, "VAT Amount" = 21, "Amount Including VAT" = 121, "Line Amount" = 100
    end;

    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseStatisticsModalPageHandler')]
    [Scope('OnPrem')]
    procedure StatsForPurchInvoiceWithTwoVATAmountLinesWithNonDedVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoice: TestPage "Purchase Invoice";
        NonDeductibleVATPct: array[2] of Integer;
        AmountWithoutVAT: array[2] of Decimal;
        VATAmount: array[2] of Decimal;
        NonDeductibleVATAmount: array[2] of Decimal;
        AmountWithoutVATAndDiscount: Decimal;
    begin
        // [FEATURE] [Normal VAT] [Statistics] [Purchase Invoice]
        // [SCENARIO 381271] Show Statistics for Purchase Invoice where 2 lines with Non-Deductible VAT generate 2 VAT Amount lines.
        Initialize();

        // [GIVEN] Purchase Invoice with "Non Deductible VAT" = 50%, VAT% = 21 , "Amount Excl. VAT" = 100.
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandInt(30));
        SetupAmountsForNonVATPurchaseStatOneLine(
          NonDeductibleVATPct, AmountWithoutVAT, AmountWithoutVATAndDiscount,
          VATAmount, NonDeductibleVATAmount, LibraryRandom.RandIntInRange(5, 10), 0, VATPostingSetup."VAT %");
        CreatePurchInvoiceWithNonDeductibleVAT(
          PurchaseHeader, VATPostingSetup, AmountWithoutVAT[1], NonDeductibleVATPct[1]);

        // [GIVEN] Second Purchase Invoice Line with "Amount Excl. VAT" = 200 and different "VAT Prod. Posting Group"
        CreateCopyPurchaseLine(PurchaseLine, PurchaseHeader, VATPostingSetup);

        VATAmount[2] := PurchaseLine."Amount Including VAT" - PurchaseLine.Amount;
        NonDeductibleVATAmount[2] := Round(VATAmount[2] * PurchaseLine."Non Deductible VAT %" / 100);

        // Enqueue amounts for PurchaseStatisticsModalPageHandler
        EnqueueAmountsForPurchStatisticsHandler(NonDeductibleVATAmount, VATAmount, AmountWithoutVAT[1], PurchaseLine.Amount, false);

        // [WHEN] Open Statistics for Purchase Invoice
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchaseHeader);
        PurchaseInvoice.Statistics.Invoke();

        // Verification is done inside PurchaseStatisticsModalPageHandler
        // [THEN] General Tab has "21% VAT" = 21, "Total Incl. VAT" = 363, Purchase (LCY) = 331.50 (100 + 10.50 + 200 + 21)
        // [THEN] VAT Line 1 has "VAT Base (Lowered)" = "Line Amount" = 110.50, "VAT Amount" = 10.50 (non-ded VAT = 10.50), "Amount Including VAT" = 121
        // [THEN] VAT Line 2 has "VAT Base (Lowered)" = "Line Amount" = 221, "VAT Amount" = 21 (non-ded VAT = 21), "Amount Including VAT" = 242
    end;
#endif

    [Test]
    [HandlerFunctions('PurchaseStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure PurchStatsForOnePurchInvoiceWhenAnotherInvoiceHasNonDedVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
        VATPostingSetup2: Record "VAT Posting Setup";
        PurchaseInvoice: TestPage "Purchase Invoice";
        NonDeductibleVATPct: array[2] of Integer;
        AmountWithoutVAT: array[2] of Decimal;
        VATAmount: array[2] of Decimal;
        NonDeductibleVATAmount: array[2] of Decimal;
        AmountWithoutVATAndDiscount: Decimal;
    begin
        // [FEATURE] [Normal VAT] [Statistics] [Purchase Invoice]
        // [SCENARIO 381042] Show Statistics for Purchase Invoice when another Invoice has Non-Deductible VAT.
        Initialize();

        // [GIVEN] Purchase Invoice "PI" with "Non Deductible VAT" = 0, VAT% = 21, "Amount Excl. VAT" = 100.
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandInt(30));
        SetupAmountsForNonVATPurchaseStatOneLine(
          NonDeductibleVATPct, AmountWithoutVAT, AmountWithoutVATAndDiscount, VATAmount, NonDeductibleVATAmount, 0, 0,
          VATPostingSetup."VAT %");
        CreatePurchInvoiceWithNonDeductibleVAT(
          PurchaseHeader, VATPostingSetup, AmountWithoutVAT[1], NonDeductibleVATPct[1]);

        // [GIVEN] Second Purchase Invoice with non-deductible VAT and different "VAT Prod. Posting Group"
        CreateCopyVATPostingSetup(VATPostingSetup2, VATPostingSetup);
        CreatePurchInvoiceWithNonDeductibleVAT(
          PurchaseHeader2, VATPostingSetup2, LibraryRandom.RandDecInRange(100, 200, 2), LibraryRandom.RandInt(10));

        // Enqueue amounts for PurchaseStatisticsPageHandler
        EnqueueAmountsForPurchStatisticsHandler(NonDeductibleVATAmount, VATAmount, AmountWithoutVAT[1], 0, true);

        // [WHEN] Open Statistics for Purchase Invoice "PI"
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchaseHeader);
        PurchaseInvoice.PurchaseStatistics.Invoke();

        // Verification is done inside PurchaseStatisticsPageHandler
        // [THEN] General Tab has "21% VAT" = 21, "Total Incl. VAT" = 121, Purchase (LCY) = 100
        // [THEN] Lines Tab has "VAT Base (Lowered)" = 100, "VAT Amount" = 21, "Amount Including VAT" = 121, "Line Amount" = 100
    end;

    [Test]
    [HandlerFunctions('PurchaseStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure PurchStatsForPurchInvoiceWithTwoVATAmountLinesWithNonDedVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoice: TestPage "Purchase Invoice";
        NonDeductibleVATPct: array[2] of Integer;
        AmountWithoutVAT: array[2] of Decimal;
        VATAmount: array[2] of Decimal;
        NonDeductibleVATAmount: array[2] of Decimal;
        AmountWithoutVATAndDiscount: Decimal;
    begin
        // [FEATURE] [Normal VAT] [Statistics] [Purchase Invoice]
        // [SCENARIO 381271] Show Statistics for Purchase Invoice where 2 lines with Non-Deductible VAT generate 2 VAT Amount lines.
        Initialize();

        // [GIVEN] Purchase Invoice with "Non Deductible VAT" = 50%, VAT% = 21 , "Amount Excl. VAT" = 100.
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandInt(30));
        SetupAmountsForNonVATPurchaseStatOneLine(
          NonDeductibleVATPct, AmountWithoutVAT, AmountWithoutVATAndDiscount,
          VATAmount, NonDeductibleVATAmount, LibraryRandom.RandIntInRange(5, 10), 0, VATPostingSetup."VAT %");
        CreatePurchInvoiceWithNonDeductibleVAT(
          PurchaseHeader, VATPostingSetup, AmountWithoutVAT[1], NonDeductibleVATPct[1]);

        // [GIVEN] Second Purchase Invoice Line with "Amount Excl. VAT" = 200 and different "VAT Prod. Posting Group"
        CreateCopyPurchaseLine(PurchaseLine, PurchaseHeader, VATPostingSetup);

        VATAmount[2] := PurchaseLine."Amount Including VAT" - PurchaseLine.Amount;
        NonDeductibleVATAmount[2] := Round(VATAmount[2] * PurchaseLine."Non Deductible VAT %" / 100);

        // Enqueue amounts for PurchaseStatisticsPageHandler
        EnqueueAmountsForPurchStatisticsHandler(NonDeductibleVATAmount, VATAmount, AmountWithoutVAT[1], PurchaseLine.Amount, false);

        // [WHEN] Open Statistics for Purchase Invoice
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchaseHeader);
        PurchaseInvoice.PurchaseStatistics.Invoke();

        // Verification is done inside PurchaseStatisticsPageHandler
        // [THEN] General Tab has "21% VAT" = 21, "Total Incl. VAT" = 363, Purchase (LCY) = 331.50 (100 + 10.50 + 200 + 21)
        // [THEN] VAT Line 1 has "VAT Base (Lowered)" = "Line Amount" = 110.50, "VAT Amount" = 10.50 (non-ded VAT = 10.50), "Amount Including VAT" = 121
        // [THEN] VAT Line 2 has "VAT Base (Lowered)" = "Line Amount" = 221, "VAT Amount" = 21 (non-ded VAT = 21), "Amount Including VAT" = 242
    end;

    [Test]
    [HandlerFunctions('PostedPurchaseStatisticsModalPageHandler')]
    [Scope('OnPrem')]
    procedure StatsForPostedPurchInvoiceWithTwoVATAmountLinesWithNonDedVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
        NonDeductibleVATPct: array[2] of Integer;
        AmountWithoutVAT: array[2] of Decimal;
        VATAmount: array[2] of Decimal;
        NonDeductibleVATAmount: array[2] of Decimal;
        AmountWithoutVATAndDiscount: Decimal;
    begin
        // [FEATURE] [Normal VAT] [Statistics] [Purchase Invoice]
        // [SCENARIO 381271] Show Statistics for Posted Purchase Invoice where 2 lines with Non-Deductible VAT generate 2 VAT Amount lines.
        Initialize();

        // [GIVEN] Posted Purchase Invoice with "Non Deductible VAT" = 50%, VAT% = 21, "Amount Excl. VAT" = 100.
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandInt(30));
        SetupAmountsForNonVATPurchaseStatOneLine(
          NonDeductibleVATPct, AmountWithoutVAT, AmountWithoutVATAndDiscount,
          VATAmount, NonDeductibleVATAmount, LibraryRandom.RandIntInRange(5, 10), 0, VATPostingSetup."VAT %");
        CreatePurchInvoiceWithNonDeductibleVAT(
          PurchaseHeader, VATPostingSetup, AmountWithoutVAT[1], NonDeductibleVATPct[1]);

        // [GIVEN] Second Purchase Invoice Line with "Amount Excl. VAT" = 200 and different "VAT Prod. Posting Group"
        CreateCopyPurchaseLine(PurchaseLine, PurchaseHeader, VATPostingSetup);
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        VATAmount[2] := PurchaseLine."Amount Including VAT" - PurchaseLine.Amount;
        NonDeductibleVATAmount[2] := Round(VATAmount[2] * PurchaseLine."Non Deductible VAT %" / 100);

        // Enqueue amounts for PurchaseStatisticsModalPageHandler
        EnqueueAmountsForPurchStatisticsHandler(NonDeductibleVATAmount, VATAmount, AmountWithoutVAT[1], PurchaseLine.Amount, false);

        // [WHEN] Openning Statistics for Posted Purchase Invoice
        PostedPurchaseInvoice.OpenEdit();
        PostedPurchaseInvoice.GotoRecord(PurchInvHeader);
        PostedPurchaseInvoice.Statistics.Invoke();

        // Verification is done inside PostedPurchaseStatisticsModalPageHandler
        // [THEN] General Tab has "21% VAT" = 21, "Total Incl. VAT" = 363, Purchase (LCY) = 331.50 (100 + 10.50 + 200 + 21)
        // [THEN] VAT Line 1 has "VAT Base (Lowered)" = "Line Amount" = 110.50, "VAT Amount" = 10.50 (non-ded VAT = 10.50), "Amount Including VAT" = 121
        // [THEN] VAT Line 2 has "VAT Base (Lowered)" = "Line Amount" = 221, "VAT Amount" = 21 (non-ded VAT = 21), "Amount Including VAT" = 242
    end;

    [Test]
    [HandlerFunctions('RHCalcAndPostVATSettlement')]
    [Scope('OnPrem')]
    procedure VATSettlementWithSeveralReverseNonDeductibleVATEntries()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        GLAccountNo: Code[20];
        InvoiceNo: array[2] of Code[20];
        BaseAmount: array[2] of Decimal;
        VATAmount: array[2] of Decimal;
        NonDedVATAmount: array[2] of Decimal;
        i: Integer;
    begin
        // [FEATURE] [VAT Settlement] [Reverse Charge VAT]
        // [SCENARIO 376014] Calc and Post VAT Settlement for several "Reverse Charge" Non Deductible VAT Entries
        Initialize();

        // [GIVEN] G/L Account "X" with Reverse Charge 20% and Non Deductible VAT 40%
        CreateVATSetupWithGLAccount(
          VATPostingSetup, GLAccount, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", LibraryRandom.RandIntInRange(20, 40));

        // [GIVEN] Posted Purchase Invoice "A" with G/L Account "X":
        // [GIVEN] Amount = 1000. Non Ded. VAT Amount  = 80 = 200 * 40%, VAT Amount = 120 = 200 - 80, VAT Base = 1080 = 1000 + 80
        // [GIVEN] Posted Purchase Invoice "B" with G/L Account "X":
        // [GIVEN] Amount = 2000, Non Ded. VAT Amount  = 160 = 400 * 40%, VAT Amount = 240 = 400 - 160, VAT Base = 2160 = 2000 + 160
        for i := 1 to ArrayLen(BaseAmount) do
            InvoiceNo[i] := CreateAndPostPurchaseInvoice(VATPostingSetup, '', GLAccount, BaseAmount[i], VATAmount[i], NonDedVATAmount[i]);

        // [WHEN] Print REP 20 "Calc. and Post VAT Settlement" with VAT Settlement Account = "Y"
        VATPostingSetup.SetRecFilter();
        GLAccountNo := SaveCalcAndPostVATSettlementReport(VATPostingSetup, true);

        // [THEN] G/L entries balance for VATSetup."Purchase VAT Account" and "Reverse Chrg. VAT Acc." = 240 = 80 + 160
        VerifyVATAccAndRevChrgAccBalance(VATPostingSetup, NonDedVATAmount[1] + NonDedVATAmount[2]);

        // [THEN] Balancing G/L Entry created for G/L Account No. = "Y" with Amount = -240
        VerifyGLEntryAmount(GLAccountNo, -(NonDedVATAmount[1] + NonDedVATAmount[2]));

        // [THEN] Report has been printed with following values:
        LibraryReportValidation.OpenExcelFile();
        // [THEN] VAT Entry Line1: DocumentNo = "A", Base = 1080, Amount = 120, Non Ded. VAT Amount = 80
        VerifyVATSettlementReportVATEntryRow(18, InvoiceNo[1], BaseAmount[1], VATAmount[1], NonDedVATAmount[1]);
        // [THEN] VAT Entry Line2: DocumentNo = "B", Base = 2160, Amount = 240, Non Ded. VAT Amount = 160
        VerifyVATSettlementReportVATEntryRow(19, InvoiceNo[2], BaseAmount[2], VATAmount[2], NonDedVATAmount[2]);
        // [THEN] Subtotal VAT Amount = -360 = -(120 + 240)
        VerifyVATSettlementReportVATAmount(20, -(VATAmount[1] + VATAmount[2]));
        // [THEN] Total VAT Amount = 600 = 200 + 400
        VerifyVATSettlementReportVATAmount(21, VATAmount[1] + NonDedVATAmount[1] + VATAmount[2] + NonDedVATAmount[2]);
        // [THEN] Total VAT Setttlement Amount = -240 = 360 - 600
        VerifyVATSettlementReportVATAmount(22, -(NonDedVATAmount[1] + NonDedVATAmount[2]));

        // Tear Down
        VATPostingSetup.Delete();
    end;

    [Test]
    [HandlerFunctions('RHCalcAndPostVATSettlement')]
    [Scope('OnPrem')]
    procedure VATSettlementForNormalAndReverseNonDeductibleVATEntries()
    var
        VATPostingSetup: array[2] of Record "VAT Posting Setup";
        GLAccount: array[2] of Record "G/L Account";
        InvoiceNo: array[2] of Code[20];
        GLAccountNo: Code[20];
        BaseAmount: array[2] of Decimal;
        VATAmount: array[2] of Decimal;
        NonDedVATAmount: array[2] of Decimal;
        i: Integer;
    begin
        // [FEATURE] [VAT Settlement] [Reverse Charge VAT]
        // [SCENARIO 207663] Calc and Post VAT Settlement for "Normal" and "Reverse Charge" Non Deductible VAT Entries
        Initialize();

        // [GIVEN] G/L Account "X" with "Normal" VAT Posting Setup with VAT% = 20
        // [GIVEN] G/L Account "Y" with "Reverse Charge" VAT Posting Setup with VAT% = 20 and Non Deductible VAT 40%
        CreateVATSetupWithGLAccount(
          VATPostingSetup[1], GLAccount[1], VATPostingSetup[1]."VAT Calculation Type"::"Normal VAT", 0);
        CreateVATSetupWithGLAccount(
          VATPostingSetup[2], GLAccount[2], VATPostingSetup[2]."VAT Calculation Type"::"Reverse Charge VAT",
          LibraryRandom.RandIntInRange(20, 40));

        // [GIVEN] Posted Purchase Invoice "A" with G/L Account "X":
        // [GIVEN] Amount = 1000, VAT Amount = 200, VAT Base = 1080
        // [GIVEN] Posted Purchase Invoice "B" with G/L Account "Y":
        // [GIVEN] Amount = 2000, Non Ded. VAT Amount  = 160 = 400 * 40%, VAT Amount = 240 = 400 - 160, VAT Base = 2160 = 2000 + 160
        for i := 1 to ArrayLen(VATPostingSetup) do
            InvoiceNo[i] := CreateAndPostPurchaseInvoice(VATPostingSetup[i], '', GLAccount[i], BaseAmount[i], VATAmount[i], NonDedVATAmount[i]);

        // [WHEN] Print REP 20 "Calc. and Post VAT Settlement" with VAT Settlement Account = "Z"
        VATPostingSetup[1].SetFilter(
          "VAT Bus. Posting Group", '%1|%2', VATPostingSetup[1]."VAT Bus. Posting Group", VATPostingSetup[2]."VAT Bus. Posting Group");
        GLAccountNo := SaveCalcAndPostVATSettlementReport(VATPostingSetup[1], true);

        // [THEN] G/L entries balance for "Normal" VATSetup."Purchase VAT Account" = 200
        VerifyVATAccAndRevChrgAccBalance(VATPostingSetup[1], -VATAmount[1]);

        // [THEN] G/L entries balance for "Reverse Charge" VATSetup."Purchase VAT Account" and "Reverse Chrg. VAT Acc." = 160
        VerifyVATAccAndRevChrgAccBalance(VATPostingSetup[2], NonDedVATAmount[2]);

        // [THEN] Balancing G/L Entry created for G/L Account No. = "Z" with Amount = 40 = 200 - 160
        VerifyGLEntryAmount(GLAccountNo, VATAmount[1] - NonDedVATAmount[2]);

        // [THEN] Report has been printed with following values:
        LibraryReportValidation.OpenExcelFile();
        // [THEN] First VAT Entry corresponds to "Normal" VAT Setup: DocumentNo = "A", Base = 1000, Amount = 200, Non Ded. VAT Amount = 0
        VerifyVATSettlementReportVATSetupValues(17, VATPostingSetup[1]);
        VerifyVATSettlementReportVATEntryRow(18, InvoiceNo[1], BaseAmount[1], VATAmount[1], 0);
        // [THEN] Subtotal "Normal" VAT Amount = -200
        VerifyVATSettlementReportVATAmount(19, -VATAmount[1]);
        // [THEN] Second VAT Entry corresponds to "Reverse Charge" VAT Setup: DocumentNo = "B", Base = 2160, Amount = 240, Non Ded. VAT Amount = 160
        VerifyVATSettlementReportVATSetupValues(20, VATPostingSetup[2]);
        VerifyVATSettlementReportVATEntryRow(21, InvoiceNo[2], BaseAmount[2], VATAmount[2], NonDedVATAmount[2]);
        // [THEN] Subtotal "Reverse Charge" VAT Amount = -240
        VerifyVATSettlementReportVATAmount(22, -VATAmount[2]);
        // [THEN] Total "Reverse Charge" VAT Amount = 400
        VerifyVATSettlementReportVATAmount(23, VATAmount[2] + NonDedVATAmount[2]);
        // [THEN] Total VAT Setttlement Amount = 40 = 200 - 160
        VerifyVATSettlementReportVATAmount(24, VATAmount[1] - NonDedVATAmount[2]);

        // Tear Down
        VATPostingSetup[1].DeleteAll();
    end;

    [Test]
    [HandlerFunctions('RHCalcAndPostVATSettlement')]
    [Scope('OnPrem')]
    procedure VATSettlementForReverseNonDeductibleAndNormalVATEntries()
    var
        VATPostingSetup: array[2] of Record "VAT Posting Setup";
        GLAccount: array[2] of Record "G/L Account";
        InvoiceNo: array[2] of Code[20];
        GLAccountNo: Code[20];
        BaseAmount: array[2] of Decimal;
        VATAmount: array[2] of Decimal;
        NonDedVATAmount: array[2] of Decimal;
        i: Integer;
    begin
        // [FEATURE] [VAT Settlement] [Reverse Charge VAT]
        // [SCENARIO 207663] Calc and Post VAT Settlement for "Reverse Charge" Non Deductible and "Normal" VAT Entries
        Initialize();

        // [GIVEN] G/L Account "X" with "Reverse Charge" VAT Posting Setup with VAT% = 20, Non Deductible VAT 40%
        // [GIVEN] G/L Account "Y" with "Normal" VAT Posting Setup with VAT% = 20
        CreateVATSetupWithGLAccount(
          VATPostingSetup[1], GLAccount[1], VATPostingSetup[1]."VAT Calculation Type"::"Reverse Charge VAT",
          LibraryRandom.RandIntInRange(20, 40));
        CreateVATSetupWithGLAccount(
          VATPostingSetup[2], GLAccount[2], VATPostingSetup[2]."VAT Calculation Type"::"Normal VAT", 0);

        // [GIVEN] Posted Purchase Invoice "A" with G/L Account "X":
        // [GIVEN] Amount = 2000, Non Ded. VAT Amount  = 160 = 400 * 40%, VAT Amount = 240 = 400 - 160, VAT Base = 2160 = 2000 + 160
        // [GIVEN] Posted Purchase Invoice "B" with G/L Account "Y":
        // [GIVEN] Amount = 1000, VAT Amount = 200, VAT Base = 1080
        for i := 1 to ArrayLen(VATPostingSetup) do
            InvoiceNo[i] := CreateAndPostPurchaseInvoice(VATPostingSetup[i], '', GLAccount[i], BaseAmount[i], VATAmount[i], NonDedVATAmount[i]);

        // [WHEN] Print REP 20 "Calc. and Post VAT Settlement" with VAT Settlement Account = "Z"
        VATPostingSetup[1].SetFilter(
          "VAT Bus. Posting Group", '%1|%2', VATPostingSetup[1]."VAT Bus. Posting Group", VATPostingSetup[2]."VAT Bus. Posting Group");
        GLAccountNo := SaveCalcAndPostVATSettlementReport(VATPostingSetup[1], true);

        // [THEN] G/L entries balance for "Reverse Charge" VATSetup."Purchase VAT Account" and "Reverse Chrg. VAT Acc." = 160
        VerifyVATAccAndRevChrgAccBalance(VATPostingSetup[1], NonDedVATAmount[1]);

        // [THEN] G/L entries balance for "Normal" VATSetup."Purchase VAT Account" = 200
        VerifyVATAccAndRevChrgAccBalance(VATPostingSetup[2], -VATAmount[2]);

        // [THEN] Balancing G/L Entry created for G/L Account No. = "Z" with Amount = 40 = 200 - 160
        VerifyGLEntryAmount(GLAccountNo, VATAmount[2] - NonDedVATAmount[1]);

        // [THEN] Report has been printed with following values:
        LibraryReportValidation.OpenExcelFile();
        // [THEN] First VAT Entry corresponds to "Reverse Charge" VAT Setup: DocumentNo = "A", Base = 2160, Amount = 240, Non Ded. VAT Amount = 160
        VerifyVATSettlementReportVATSetupValues(17, VATPostingSetup[1]);
        VerifyVATSettlementReportVATEntryRow(18, InvoiceNo[1], BaseAmount[1], VATAmount[1], NonDedVATAmount[1]);
        // [THEN] Subtotal "Reverse Charge" VAT Amount = -240
        VerifyVATSettlementReportVATAmount(19, -VATAmount[1]);
        // [THEN] Total "Reverse Charge" VAT Amount = 400
        VerifyVATSettlementReportVATAmount(20, VATAmount[1] + NonDedVATAmount[1]);
        // [THEN] Second VAT Entry corresponds to "Normal" VAT Setup: DocumentNo = "B", Base = 1000, Amount = 200, Non Ded. VAT Amount = 0
        VerifyVATSettlementReportVATSetupValues(21, VATPostingSetup[2]);
        VerifyVATSettlementReportVATEntryRow(22, InvoiceNo[2], BaseAmount[2], VATAmount[2], 0);
        // [THEN] Subtotal "Normal" VAT Amount = -200
        VerifyVATSettlementReportVATAmount(23, -VATAmount[2]);
        // [THEN] Total VAT Setttlement Amount = 40 = 200 - 160
        VerifyVATSettlementReportVATAmount(24, VATAmount[2] - NonDedVATAmount[1]);

        // Tear Down
        VATPostingSetup[1].DeleteAll();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NonDedSourceCurrVATAmt_LCY()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        PurchInvHeader: Record "Purch. Inv. Header";
        VATBase: Decimal;
        VATAmount: Decimal;
        NonDedVATAmount: Decimal;
    begin
        // [FEATURE] [Additional Currency] [Report] [VAT Statement]
        // [SCENARIO 219115] VATEntry."Non Ded. Source Curr. VAT Amt." = 0 in case of blanked ACY and posted LCY purchase invoice.
        // [SCENARIO 251548] VAT Statement "Include Non Deductible VAT" = TRUE shows full VAT amount (TFS 251548).
        Initialize();

        // [GIVEN] GLSetup."Additional Reporting Currency" = ""
        LibraryERM.SetAddReportingCurrency('');

        // [GIVEN] G/L Account "X" with Reverse Charge 20% and Non Deductible VAT 40%
        CreateVATSetupWithGLAccount(
          VATPostingSetup, GLAccount, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", LibraryRandom.RandIntInRange(20, 40));

        // [WHEN] Post purchase invoice (LCY) with G/L Account "X" and Amount = 1000
        PurchInvHeader.Get(CreateAndPostPurchaseInvoice(VATPostingSetup, '', GLAccount, VATBase, VATAmount, NonDedVATAmount));

        // [THEN] VATEntry."Non Ded. VAT Amount" = (1000 * 20%) * 40% = 80
        // [THEN] VATEntry."Base" = 1000 + 80 = 1080
        // [THEN] VATEntry."Amount" = (1000 * 20%) - 80 = 120
        // [THEN] VATEntry."Non Ded. Source Curr. VAT Amt." = 0
        // [THEN] VATEntry."Additional-Currency Base" = 0
        // [THEN] VATEntry."Additional-Currency Amount" = 0
        VerifyVATEntryLCYAndACYAmounts(
          PurchInvHeader."Buy-from Vendor No.", PurchInvHeader."No.",
          VATBase, VATAmount, NonDedVATAmount, 0, 0, 0);

        // [THEN] VAT Statement Line has following Base and Amount:
        // [THEN] InclNonDeductibleVAT = FALSE, UseAmtsInAddCurr = FALSE: Base = 1080, Amount = 120
        // [THEN] InclNonDeductibleVAT = TRUE, UseAmtsInAddCurr = FALSE: Base = 1000, Amount = 200
        // [THEN] InclNonDeductibleVAT = FALSE, UseAmtsInAddCurr = TRUE: Base = 0, Amount = 0
        // [THEN] InclNonDeductibleVAT = TRUE, UseAmtsInAddCurr = TRUE: Base = 0, Amount = 0
        VerifyVATStatementAmountsLCYAndACY(VATPostingSetup, VATBase, VATAmount, NonDedVATAmount, 0, 0, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NonDedSourceCurrVATAmt_FCY()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        PurchInvHeader: Record "Purch. Inv. Header";
        VATBase: Decimal;
        VATAmount: Decimal;
        NonDedVATAmount: Decimal;
        VATBaseLCY: Decimal;
        VATAmountLCY: Decimal;
        NonDedVATAmountLCY: Decimal;
    begin
        // [FEATURE] [Additional Currency] [Currency] [Report] [VAT Statement]
        // [SCENARIO 219115] VATEntry."Non Ded. Source Curr. VAT Amt." = 0 in case of blanked ACY and posted FCY purchase invoice.
        // [SCENARIO 251548] VAT Statement "Include Non Deductible VAT" = TRUE shows full VAT amount (TFS 251548).
        Initialize();
        LibraryPurchase.SetInvoiceRounding(false);

        // [GIVEN] GLSetup."Additional Reporting Currency" = ""
        LibraryERM.SetAddReportingCurrency('');

        // [GIVEN] G/L Account "X" with Reverse Charge 20% and Non Deductible VAT 40%
        CreateVATSetupWithGLAccount(
          VATPostingSetup, GLAccount, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", LibraryRandom.RandIntInRange(20, 40));

        // [WHEN] Post purchase invoice (FCY, FCY to LCY currency factor = 10) with G/L Account "X" and Amount = 1000
        PurchInvHeader.Get(
          CreateAndPostPurchaseInvoiceWithFCY(
            VATPostingSetup, LibraryERM.CreateCurrencyWithRandomExchRates(), GLAccount, VATBase, VATAmount, NonDedVATAmount, VATBaseLCY, VATAmountLCY, NonDedVATAmountLCY));

        // [THEN] VATEntry."Non Ded. VAT Amount" = (10000 * 20%) * 40% = 800
        // [THEN] VATEntry."Base" = 10000 + 800 = 10800
        // [THEN] VATEntry."Amount" = (10000 * 20%) - 800 = 1200
        // [THEN] VATEntry."Non Ded. Source Curr. VAT Amt." = 0
        // [THEN] VATEntry."Additional-Currency Base" = 0
        // [THEN] VATEntry."Additional-Currency Amount" = 0
        VerifyVATEntryLCYAndACYAmounts(
          PurchInvHeader."Buy-from Vendor No.", PurchInvHeader."No.",
          VATBaseLCY, VATAmountLCY, NonDedVATAmountLCY, 0, 0, 0);

        // [THEN] VAT Statement Line has following Base and Amount:
        // [THEN] InclNonDeductibleVAT = FALSE, UseAmtsInAddCurr = FALSE: Base = 10800, Amount = 1200
        // [THEN] InclNonDeductibleVAT = TRUE, UseAmtsInAddCurr = FALSE: Base = 10000, Amount = 2000
        // [THEN] InclNonDeductibleVAT = FALSE, UseAmtsInAddCurr = TRUE: Base = 0, Amount = 0
        // [THEN] InclNonDeductibleVAT = TRUE, UseAmtsInAddCurr = TRUE: Base = 0, Amount = 0
        VerifyVATStatementAmountsLCYAndACY(VATPostingSetup, VATBaseLCY, VATAmountLCY, NonDedVATAmountLCY, 0, 0, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NonDedSourceCurrVATAmt_ACY_LCY()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        PurchInvHeader: Record "Purch. Inv. Header";
        VATBase: Decimal;
        VATAmount: Decimal;
        NonDedVATAmount: Decimal;
        VATBaseACY: Decimal;
        VATAmountACY: Decimal;
        NonDedVATAmountACY: Decimal;
    begin
        // [FEATURE] [Additional Currency] [Report] [VAT Statement]
        // [SCENARIO 219115] VATEntry."Non Ded. Source Curr. VAT Amt." <> 0 in case of ACY and posted LCY purchase invoice.
        // [SCENARIO 251548] VAT Statement "Include Non Deductible VAT" = TRUE shows full VAT amount (TFS 251548).
        Initialize();

        // [GIVEN] GLSetup."Additional Reporting Currency" = "ACY" (LCY to ACY currency factor = 10)
        LibraryERM.SetAddReportingCurrency(LibraryERM.CreateCurrencyWithRandomExchRates());

        // [GIVEN] G/L Account "X" with Reverse Charge 20% and Non Deductible VAT 40%
        CreateVATSetupWithGLAccount(
          VATPostingSetup, GLAccount, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", LibraryRandom.RandIntInRange(20, 40));

        // [WHEN] Post purchase invoice (LCY) with G/L Account "X" and Amount = 1000
        PurchInvHeader.Get(CreateAndPostPurchaseInvoice(VATPostingSetup, '', GLAccount, VATBase, VATAmount, NonDedVATAmount));
        ConvertAmounts(
          VATBaseACY, VATAmountACY, NonDedVATAmountACY, VATBase, VATAmount, NonDedVATAmount, '', LibraryERM.GetAddReportingCurrency());

        // [THEN] VATEntry."Non Ded. VAT Amount" = (1000 * 20%) * 40% = 80
        // [THEN] VATEntry."Base" = 1000 + 80 = 1080
        // [THEN] VATEntry."Amount" = (1000 * 20%) - 80 = 120
        // [THEN] VATEntry."Non Ded. Source Curr. VAT Amt." = 80 * 10 = 800
        // [THEN] VATEntry."Additional-Currency Base" = 1080 * 10 = 10800
        // [THEN] VATEntry."Additional-Currency Amount" = 120 * 10 = 1200
        VerifyVATEntryLCYAndACYAmounts(
          PurchInvHeader."Buy-from Vendor No.", PurchInvHeader."No.",
          VATBase, VATAmount, NonDedVATAmount,
          VATBaseACY, VATAmountACY, NonDedVATAmountACY);

        // [THEN] VAT Statement Line has following Base and Amount:
        // [THEN] InclNonDeductibleVAT = FALSE, UseAmtsInAddCurr = FALSE: Base = 1080, Amount = 120
        // [THEN] InclNonDeductibleVAT = TRUE, UseAmtsInAddCurr = FALSE: Base = 1000, Amount = 200
        // [THEN] InclNonDeductibleVAT = FALSE, UseAmtsInAddCurr = TRUE: Base = 10800, Amount = 1200
        // [THEN] InclNonDeductibleVAT = TRUE, UseAmtsInAddCurr = TRUE: Base = 10000, Amount = 2000
        VerifyVATStatementAmountsLCYAndACY(
          VATPostingSetup,
          VATBase, VATAmount, NonDedVATAmount,
          VATBaseACY, VATAmountACY, NonDedVATAmountACY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NonDedSourceCurrVATAmt_ACY_FCY_Different()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        PurchInvHeader: Record "Purch. Inv. Header";
        VATBase: Decimal;
        VATAmount: Decimal;
        NonDedVATAmount: Decimal;
        VATBaseLCY: Decimal;
        VATAmountLCY: Decimal;
        NonDedVATAmountLCY: Decimal;
        VATBaseACY: Decimal;
        VATAmountACY: Decimal;
        NonDedVATAmountACY: Decimal;
    begin
        // [FEATURE] [Additional Currency] [Currency] [Report] [VAT Statement]
        // [SCENARIO 219115] VATEntry."Non Ded. Source Curr. VAT Amt." <> 0 in case of ACY and posted FCY purchase invoice (ACY <> FCY).
        // [SCENARIO 251548] VAT Statement "Include Non Deductible VAT" = TRUE shows full VAT amount (TFS 251548).
        Initialize();
        LibraryPurchase.SetInvoiceRounding(false);

        // [GIVEN] GLSetup."Additional Reporting Currency" = "ACY" (LCY to ACY currency factor = 10)
        LibraryERM.SetAddReportingCurrency(LibraryERM.CreateCurrencyWithRandomExchRates());

        // [GIVEN] G/L Account "X" with Reverse Charge 20% and Non Deductible VAT 40%
        CreateVATSetupWithGLAccount(
          VATPostingSetup, GLAccount, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", LibraryRandom.RandIntInRange(20, 40));

        // [WHEN] Post purchase invoice (FCY, FCY to LCY currency factor = 10) with G/L Account "X" and Amount = 1000
        PurchInvHeader.Get(
          CreateAndPostPurchaseInvoiceWithFCYAndACY(
            VATPostingSetup, LibraryERM.CreateCurrencyWithRandomExchRates(), GLAccount, VATBase, VATAmount, NonDedVATAmount,
            VATBaseLCY, VATAmountLCY, NonDedVATAmountLCY, VATBaseACY, VATAmountACY, NonDedVATAmountACY));

        // [THEN] VATEntry."Non Ded. VAT Amount" = (10000 * 20%) * 40% = 800
        // [THEN] VATEntry."Base" = 10000 + 800 = 10800
        // [THEN] VATEntry."Amount" = (10000 * 20%) - 800 = 1200
        // [THEN] VATEntry."Non Ded. Source Curr. VAT Amt." = 800 * 10 = 8000
        // [THEN] VATEntry."Additional-Currency Base" = 10800 * 10 = 108000
        // [THEN] VATEntry."Additional-Currency Amount" = 1200 * 10 = 12000
        VerifyVATEntryLCYAndACYAmounts(
          PurchInvHeader."Buy-from Vendor No.", PurchInvHeader."No.",
          VATBaseLCY, VATAmountLCY, NonDedVATAmountLCY,
          VATBaseACY, VATAmountACY, NonDedVATAmountACY);

        // [THEN] VAT Statement Line has following Base and Amount:
        // [THEN] InclNonDeductibleVAT = FALSE, UseAmtsInAddCurr = FALSE: Base = 10800, Amount = 1200
        // [THEN] InclNonDeductibleVAT = TRUE, UseAmtsInAddCurr = FALSE: Base = 10000, Amount = 2000
        // [THEN] InclNonDeductibleVAT = FALSE, UseAmtsInAddCurr = TRUE: Base = 108000, Amount = 12000
        // [THEN] InclNonDeductibleVAT = TRUE, UseAmtsInAddCurr = TRUE: Base = 100000, Amount = 20000
        VerifyVATStatementAmountsLCYAndACY(
          VATPostingSetup,
          VATBaseLCY, VATAmountLCY, NonDedVATAmountLCY,
          VATBaseACY, VATAmountACY, NonDedVATAmountACY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NonDedSourceCurrVATAmt_ACY_FCY_Equals()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        PurchInvHeader: Record "Purch. Inv. Header";
        VATBase: Decimal;
        VATAmount: Decimal;
        NonDedVATAmount: Decimal;
        VATBaseLCY: Decimal;
        VATAmountLCY: Decimal;
        NonDedVATAmountLCY: Decimal;
        VATBaseACY: Decimal;
        VATAmountACY: Decimal;
        NonDedVATAmountACY: Decimal;
    begin
        // [FEATURE] [Additional Currency] [Currency] [Report] [VAT Statement]
        // [SCENARIO 219115] VATEntry."Non Ded. Source Curr. VAT Amt." <> 0 in case of ACY and posted FCY purchase invoice (ACY = FCY).
        // [SCENARIO 251548] VAT Statement "Include Non Deductible VAT" = TRUE shows full VAT amount (TFS 251548).
        Initialize();
        LibraryPurchase.SetInvoiceRounding(false);

        // [GIVEN] GLSetup."Additional Reporting Currency" = "ACY" (LCY to ACY currency factor = 10)
        LibraryERM.SetAddReportingCurrency(LibraryERM.CreateCurrencyWithRandomExchRates());

        // [GIVEN] G/L Account "X" with Reverse Charge 20% and Non Deductible VAT 40%
        CreateVATSetupWithGLAccount(
          VATPostingSetup, GLAccount, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", LibraryRandom.RandIntInRange(20, 40));

        // [WHEN] Post purchase invoice (FCY, FCY = ACY) with G/L Account "X" and Amount = 1000
        PurchInvHeader.Get(
          CreateAndPostPurchaseInvoiceWithFCYAndACY(
            VATPostingSetup, LibraryERM.GetAddReportingCurrency(), GLAccount, VATBase, VATAmount, NonDedVATAmount,
            VATBaseLCY, VATAmountLCY, NonDedVATAmountLCY, VATBaseACY, VATAmountACY, NonDedVATAmountACY));

        // [THEN] VATEntry."Non Ded. VAT Amount" = (100 * 20%) * 40% = 8
        // [THEN] VATEntry."Base" = 100 + 8 = 108
        // [THEN] VATEntry."Amount" = (100 * 20%) - 8 = 12
        // [THEN] VATEntry."Non Ded. Source Curr. VAT Amt." = 80
        // [THEN] VATEntry."Additional-Currency Base" = 1080
        // [THEN] VATEntry."Additional-Currency Amount" = 120
        VerifyVATEntryLCYAndACYAmounts(
          PurchInvHeader."Buy-from Vendor No.", PurchInvHeader."No.",
          VATBaseLCY, VATAmountLCY, NonDedVATAmountLCY,
          VATBase, VATAmount, NonDedVATAmount);

        // [THEN] VAT Statement Line has following Base and Amount:
        // [THEN] InclNonDeductibleVAT = FALSE, UseAmtsInAddCurr = FALSE: Base = 108, Amount = 12
        // [THEN] InclNonDeductibleVAT = TRUE, UseAmtsInAddCurr = FALSE: Base = 100, Amount = 20
        // [THEN] InclNonDeductibleVAT = FALSE, UseAmtsInAddCurr = TRUE: Base = 1080, Amount = 120
        // [THEN] InclNonDeductibleVAT = TRUE, UseAmtsInAddCurr = TRUE: Base = 1000, Amount = 200
        VerifyVATStatementAmountsLCYAndACY(
          VATPostingSetup,
          VATBaseLCY, VATAmountLCY, NonDedVATAmountLCY,
          VATBase, VATAmount, NonDedVATAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchInvWithDeferralAndNonDedVAT()
    var
        DeferralTemplate: Record "Deferral Template";
        PurchaseHeader: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
        DeferredAmount: Decimal;
        DocNo: Code[20];
    begin
        // [SCENARIO 269930] Deffered G/L Entries must contain correct amounts after posting Purchase Invoice with Deferrals and Non Deductible VAT.
        Initialize();

        // [GIVEN] VAT Posting Setup with "VAT %" = 21
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandInt(30));

        // [GIVEN] "Deferral Template" with "Period No." = 2 and "Calc. Method" = "Straight-Line"
        LibraryERM.CreateDeferralTemplate(
          DeferralTemplate, DeferralTemplate."Calc. Method"::"Straight-Line",
          DeferralTemplate."Start Date"::"Posting Date", LibraryRandom.RandIntInRange(2, 5) * 2);

        // [GIVEN] Purchase Invoice with Purchase Line
        // [GIVEN] Amount = 1000, "Deferral Code" = "Deferral Template".Code, "Non Deductible VAT %" = 65
        DeferredAmount := CreatePurchInvoiceWithDeferralAndNonDedVAT(PurchaseHeader, VATPostingSetup, DeferralTemplate."Deferral Code");

        // [WHEN] Post purchase invoice
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Total Deferral Amount = 1136,5 (1000 + 210 - 210 / 100 * 35)
        // [THEN] 2 G/L Entries with Amount = 568,25
        VerifyGLEntryDeferrals(
          DeferralTemplate."Deferral Account", DocNo,
          DeferredAmount,
          DeferralTemplate."No. of Periods");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure COD57_CalculatePurchaseSubPageTotals_WithNonDeductVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        TotalPurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TotalPurchaseLine: Record "Purchase Line";
        DocumentTotals: Codeunit "Document Totals";
        VATAmount: Decimal;
        InvoiceDiscountAmount: Decimal;
        InvoiceDiscountPct: Decimal;
    begin
        // [FEATURE] [Document Totals] [UT]
        // [SCENARIO 291696] Document Totals does not involve non-deductible VAT from other documents
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(),
          LibraryRandom.RandIntInRange(100, 200));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(100, 200));
        PurchaseLine.Validate("VAT %", LibraryRandom.RandIntInRange(10, 30));
        PurchaseLine.Validate("Non Deductible VAT %", LibraryRandom.RandIntInRange(10, 30));
        PurchaseLine.Modify(true);

        Clear(TotalPurchaseHeader);
        DocumentTotals.CalculatePurchaseSubPageTotals(
          TotalPurchaseHeader, TotalPurchaseLine, VATAmount, InvoiceDiscountAmount, InvoiceDiscountPct);

        Assert.AreEqual(0, VATAmount, '');
        Assert.AreEqual(0, InvoiceDiscountAmount, '');
        Assert.AreEqual(0, InvoiceDiscountPct, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseDeltaUpdateTotalsWhenBothLinesOfNormalVAT()
    var
        TotalPurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        NewPurchaseLine: Record "Purchase Line";
        OldPurchaseLine: Record "Purchase Line";
        ZeroPurchaseLine: Record "Purchase Line";
        DocumentTotals: Codeunit "Document Totals";
        InvDiscAmt: Decimal;
        InvDiscPcs: Decimal;
        VATAmt: Decimal;
    begin
        // [FEATURE] [Purchase] [Document Totals] [Reverse Charge VAT] [UT]
        // [SCENARIO 313336] PurchaseDeltaUpdateTotals calculates "Amount Including VAT" and VATAmount correctly when both lines "VAT Calculation Type" <> "Reverse Charge VAT".
        Initialize();

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, "Purchase Document Type".FromInteger(LibraryRandom.RandInt(5)), LibraryPurchase.CreateVendorNo());
        MockPurchaseLine(OldPurchaseLine, PurchaseHeader, OldPurchaseLine."VAT Calculation Type"::"Normal VAT", 10, 200);
        MockPurchaseLine(NewPurchaseLine, PurchaseHeader, NewPurchaseLine."VAT Calculation Type"::"Normal VAT", 10, 100);
        DocumentTotals.PurchaseDeltaUpdateTotals(OldPurchaseLine, ZeroPurchaseLine, TotalPurchaseLine, VATAmt, InvDiscAmt, InvDiscPcs);

        DocumentTotals.PurchaseDeltaUpdateTotals(NewPurchaseLine, OldPurchaseLine, TotalPurchaseLine, VATAmt, InvDiscAmt, InvDiscPcs);

        Assert.AreEqual(NewPurchaseLine."Amount Including VAT", TotalPurchaseLine."Amount Including VAT", '');
        Assert.AreEqual(NewPurchaseLine."Amount Including VAT" - NewPurchaseLine.Amount, VATAmt, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseDeltaUpdateTotalsWhenBothLinesOfReverseChargeVAT()
    var
        TotalPurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        NewPurchaseLine: Record "Purchase Line";
        OldPurchaseLine: Record "Purchase Line";
        ZeroPurchaseLine: Record "Purchase Line";
        DocumentTotals: Codeunit "Document Totals";
        InvDiscAmt: Decimal;
        InvDiscPcs: Decimal;
        VATAmt: Decimal;
    begin
        // [FEATURE] [Purchase] [Document Totals] [Reverse Charge VAT] [UT]
        // [SCENARIO 313336] PurchaseDeltaUpdateTotals calculates "Amount Including VAT" and VATAmount correctly when both lines "VAT Calculation Type" = "Reverse Charge VAT".
        Initialize();

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, "Purchase Document Type".FromInteger(LibraryRandom.RandInt(5)), LibraryPurchase.CreateVendorNo());
        MockPurchaseLine(OldPurchaseLine, PurchaseHeader, OldPurchaseLine."VAT Calculation Type"::"Reverse Charge VAT", 10, 200);
        MockPurchaseLine(NewPurchaseLine, PurchaseHeader, NewPurchaseLine."VAT Calculation Type"::"Reverse Charge VAT", 10, 100);
        DocumentTotals.PurchaseDeltaUpdateTotals(OldPurchaseLine, ZeroPurchaseLine, TotalPurchaseLine, VATAmt, InvDiscAmt, InvDiscPcs);

        DocumentTotals.PurchaseDeltaUpdateTotals(NewPurchaseLine, OldPurchaseLine, TotalPurchaseLine, VATAmt, InvDiscAmt, InvDiscPcs);

        Assert.AreEqual(NewPurchaseLine.Amount, TotalPurchaseLine."Amount Including VAT", '');
        Assert.AreEqual(0, VATAmt, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseDeltaUpdateTotalsWhenNewLineOfReverseChargeVATOldLineOfNormalVAT()
    var
        TotalPurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        NewPurchaseLine: Record "Purchase Line";
        OldPurchaseLine: Record "Purchase Line";
        ZeroPurchaseLine: Record "Purchase Line";
        DocumentTotals: Codeunit "Document Totals";
        InvDiscAmt: Decimal;
        InvDiscPcs: Decimal;
        VATAmt: Decimal;
    begin
        // [FEATURE] [Purchase] [Document Totals] [Reverse Charge VAT] [UT]
        // [SCENARIO 313336] PurchaseDeltaUpdateTotals calculates "Amount Including VAT" and VATAmount correctly when new line uses "VAT Calculation Type" = "Reverse Charge VAT", old one doesn't.
        Initialize();

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, "Purchase Document Type".FromInteger(LibraryRandom.RandInt(5)), LibraryPurchase.CreateVendorNo());
        MockPurchaseLine(OldPurchaseLine, PurchaseHeader, OldPurchaseLine."VAT Calculation Type"::"Normal VAT", 10, 200);
        MockPurchaseLine(NewPurchaseLine, PurchaseHeader, NewPurchaseLine."VAT Calculation Type"::"Reverse Charge VAT", 10, 100);
        DocumentTotals.PurchaseDeltaUpdateTotals(OldPurchaseLine, ZeroPurchaseLine, TotalPurchaseLine, VATAmt, InvDiscAmt, InvDiscPcs);

        DocumentTotals.PurchaseDeltaUpdateTotals(NewPurchaseLine, OldPurchaseLine, TotalPurchaseLine, VATAmt, InvDiscAmt, InvDiscPcs);

        Assert.AreEqual(NewPurchaseLine.Amount, TotalPurchaseLine."Amount Including VAT", '');
        Assert.AreEqual(0, VATAmt, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseDeltaUpdateTotalsWhenNewLineOfNormalVATOldLineOfReverseChargeVAT()
    var
        TotalPurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        NewPurchaseLine: Record "Purchase Line";
        OldPurchaseLine: Record "Purchase Line";
        ZeroPurchaseLine: Record "Purchase Line";
        DocumentTotals: Codeunit "Document Totals";
        InvDiscAmt: Decimal;
        InvDiscPcs: Decimal;
        VATAmt: Decimal;
    begin
        // [FEATURE] [Purchase] [Document Totals] [Reverse Charge VAT] [UT]
        // [SCENARIO 313336] PurchaseDeltaUpdateTotals calculates "Amount Including VAT" and VATAmount correctly when old line uses "VAT Calculation Type" = "Reverse Charge VAT", new one doesn't.
        Initialize();

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, "Purchase Document Type".FromInteger(LibraryRandom.RandInt(5)), LibraryPurchase.CreateVendorNo());
        MockPurchaseLine(OldPurchaseLine, PurchaseHeader, OldPurchaseLine."VAT Calculation Type"::"Reverse Charge VAT", 10, 200);
        MockPurchaseLine(NewPurchaseLine, PurchaseHeader, NewPurchaseLine."VAT Calculation Type"::"Normal VAT", 10, 100);
        DocumentTotals.PurchaseDeltaUpdateTotals(OldPurchaseLine, ZeroPurchaseLine, TotalPurchaseLine, VATAmt, InvDiscAmt, InvDiscPcs);

        DocumentTotals.PurchaseDeltaUpdateTotals(NewPurchaseLine, OldPurchaseLine, TotalPurchaseLine, VATAmt, InvDiscAmt, InvDiscPcs);

        Assert.AreEqual(NewPurchaseLine."Amount Including VAT", TotalPurchaseLine."Amount Including VAT", '');
        Assert.AreEqual(NewPurchaseLine."Amount Including VAT" - NewPurchaseLine.Amount, VATAmt, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NonDeductibleVATIsConsideredInTotalVAT_NormalVAT_PriceExclVAT()
    var
        VATCalculationType: Enum "Tax Calculation Type";
        PurchaseHeader: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: array[3] of Record "G/L Account";
    begin
        // [SCENARIO 359756] Total Exc. VAT and Total VAT are not update when use a non deductible VAT in belgium localization
        Initialize();

        // [GIVEN] Purchase Invoice with VAT setup: VAT Calculation Type is "Normal VAT" and Prices Excluding VAT
        VATCalculationType := VATCalculationType::"Normal VAT";
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
            CreateVendorNoWithVATPostingSetupAndPricesIncludingVATSetup(VATPostingSetup, VATCalculationType, false));

        // [GIVEN] G/L Account lines with different VAT setup
        // Line | Line Amnt | VAT% | N.D. VAT% | Amount  | VAT Amount
        // ----------------------------------------------------------
        // 01     117         7      23        |  118.88   6.31
        // 02     117         10     17        |  118.99   9.71
        // 03     117         17     7         |  118.39   18.50
        CreatePurchaseLineWithGLAccountAndVATPostingSetup(PurchaseHeader, VATPostingSetup, GLAccount[1], VATCalculationType, 117, 7, 23);
        VerifyTotalAmountAndTotalVAT(PurchaseHeader, 118.88, 6.31);

        CreatePurchaseLineWithGLAccountAndVATPostingSetup(PurchaseHeader, VATPostingSetup, GLAccount[2], VATCalculationType, 117, 10, 17);
        VerifyTotalAmountAndTotalVAT(PurchaseHeader, 237.87, 16.02);

        CreatePurchaseLineWithGLAccountAndVATPostingSetup(PurchaseHeader, VATPostingSetup, GLAccount[3], VATCalculationType, 117, 17, 7);
        VerifyTotalAmountAndTotalVAT(PurchaseHeader, 356.26, 34.52);

        // [WHEN] Post Purchase Invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [THEN] G/L Entries and VAT Entries created after posting should contain correct Amounts
        VerifyAmountsWithCreatedEntries(PurchaseHeader, GLAccount[1], 118.88, 6.31);
        VerifyAmountsWithCreatedEntries(PurchaseHeader, GLAccount[2], 118.99, 9.71);
        VerifyAmountsWithCreatedEntries(PurchaseHeader, GLAccount[3], 118.39, 18.50);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NonDeductibleVATIsConsideredInTotalVAT_NormalVAT_PriceInclVAT()
    var
        VATCalculationType: Enum "Tax Calculation Type";
        PurchaseHeader: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: array[3] of Record "G/L Account";
    begin
        // [SCENARIO 359756] Total Exc. VAT and Total VAT are not update when use a non deductible VAT in belgium localization
        Initialize();

        // [GIVEN] Purchase Invoice with VAT setup: VAT Calculation Type is "Normal VAT" and Prices Including VAT
        VATCalculationType := VATCalculationType::"Normal VAT";
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
            CreateVendorNoWithVATPostingSetupAndPricesIncludingVATSetup(VATPostingSetup, VATCalculationType, true));

        // [GIVEN] G/L Account lines with different VAT setup
        // Line | Line Amnt | VAT% | N.D. VAT% | Amount  | VAT Amount
        // ----------------------------------------------------------
        // 01     117         7      23        |  111.11   5.89
        // 02     117         10     17        |  108.17   8.83
        // 03     117         17     7         |  101.19   15.81
        CreatePurchaseLineWithGLAccountAndVATPostingSetup(PurchaseHeader, VATPostingSetup, GLAccount[1], VATCalculationType, 117, 7, 23);
        VerifyTotalAmountAndTotalVAT(PurchaseHeader, 111.11, 5.89);

        CreatePurchaseLineWithGLAccountAndVATPostingSetup(PurchaseHeader, VATPostingSetup, GLAccount[2], VATCalculationType, 117, 10, 17);
        VerifyTotalAmountAndTotalVAT(PurchaseHeader, 219.28, 14.72);

        CreatePurchaseLineWithGLAccountAndVATPostingSetup(PurchaseHeader, VATPostingSetup, GLAccount[3], VATCalculationType, 117, 17, 7);
        VerifyTotalAmountAndTotalVAT(PurchaseHeader, 320.47, 30.53);

        // [WHEN] Post Purchase Invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [THEN] G/L Entries and VAT Entries created after posting should contain correct Amounts
        VerifyAmountsWithCreatedEntries(PurchaseHeader, GLAccount[1], 111.11, 5.89);
        VerifyAmountsWithCreatedEntries(PurchaseHeader, GLAccount[2], 108.17, 8.83);
        VerifyAmountsWithCreatedEntries(PurchaseHeader, GLAccount[3], 101.19, 15.81);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NonDeductibleVATIsConsideredInTotalVAT_ReverseChargeVAT_PriceExclVAT()
    var
        VATCalculationType: Enum "Tax Calculation Type";
        PurchaseHeader: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: array[3] of Record "G/L Account";
    begin
        // [SCENARIO 359756] Total Exc. VAT and Total VAT are not update when use a non deductible VAT in belgium localization
        Initialize();

        // [GIVEN] Purchase Invoice with VAT setup: VAT Calculation Type is "Reverse Charge VAT" and Prices Excluding VAT
        VATCalculationType := VATCalculationType::"Reverse Charge VAT";
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
            CreateVendorNoWithVATPostingSetupAndPricesIncludingVATSetup(VATPostingSetup, VATCalculationType, false));

        // [GIVEN] G/L Account lines with different VAT setup
        // Line | Line Amnt | VAT% | N.D. VAT% | Amount  | VAT Amount
        // ----------------------------------------------------------
        // 01     117         7      23        |  117      0
        // 02     117         10     17        |  117      0
        // 03     117         17     7         |  117      0
        CreatePurchaseLineWithGLAccountAndVATPostingSetup(PurchaseHeader, VATPostingSetup, GLAccount[1], VATCalculationType, 117, 7, 23);
        VerifyTotalAmountAndTotalVAT(PurchaseHeader, 117, 0);

        CreatePurchaseLineWithGLAccountAndVATPostingSetup(PurchaseHeader, VATPostingSetup, GLAccount[2], VATCalculationType, 117, 10, 17);
        VerifyTotalAmountAndTotalVAT(PurchaseHeader, 234, 0);

        CreatePurchaseLineWithGLAccountAndVATPostingSetup(PurchaseHeader, VATPostingSetup, GLAccount[3], VATCalculationType, 117, 17, 7);
        VerifyTotalAmountAndTotalVAT(PurchaseHeader, 351, 0);

        // [WHEN] Post Purchase Invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [THEN] G/L Entries and VAT Entries created after posting should contain correct Amounts (same as with NormalVAT case)
        VerifyAmountsWithCreatedEntries(PurchaseHeader, GLAccount[1], 118.88, 6.31);
        VerifyAmountsWithCreatedEntries(PurchaseHeader, GLAccount[2], 118.99, 9.71);
        VerifyAmountsWithCreatedEntries(PurchaseHeader, GLAccount[3], 118.39, 18.50);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NonDeductibleVATIsConsideredInTotalVAT_ReverseChargeVAT_PriceInclVAT()
    var
        VATCalculationType: Enum "Tax Calculation Type";
        PurchaseHeader: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: array[3] of Record "G/L Account";
    begin
        // [SCENARIO 359756] Total Exc. VAT and Total VAT are not update when use a non deductible VAT in belgium localization
        Initialize();

        // [GIVEN] Purchase Invoice with VAT setup: VAT Calculation Type is "Reverse Charge VAT" and Prices Including VAT
        VATCalculationType := VATCalculationType::"Reverse Charge VAT";
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
            CreateVendorNoWithVATPostingSetupAndPricesIncludingVATSetup(VATPostingSetup, VATCalculationType, true));

        // [GIVEN] G/L Account lines with different VAT setup
        // Line | Line Amnt | VAT% | N.D. VAT% | Amount  | VAT Amount
        // ----------------------------------------------------------
        // 01     117         7      23        |  109.35   0
        // 02     117         10     17        |  106.36   0
        // 03     117         17     7         |  100.00   0
        CreatePurchaseLineWithGLAccountAndVATPostingSetup(PurchaseHeader, VATPostingSetup, GLAccount[1], VATCalculationType, 117, 7, 23);
        VerifyTotalAmountAndTotalVAT(PurchaseHeader, 117, 0);

        CreatePurchaseLineWithGLAccountAndVATPostingSetup(PurchaseHeader, VATPostingSetup, GLAccount[2], VATCalculationType, 117, 10, 17);
        VerifyTotalAmountAndTotalVAT(PurchaseHeader, 234, 0);

        CreatePurchaseLineWithGLAccountAndVATPostingSetup(PurchaseHeader, VATPostingSetup, GLAccount[3], VATCalculationType, 117, 17, 7);
        VerifyTotalAmountAndTotalVAT(PurchaseHeader, 351, 0);

        /// [WHEN] Post Purchase Invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [THEN] G/L Entries and VAT Entries created after posting should contain correct Amounts (same as with NormalVAT case)
        VerifyAmountsWithCreatedEntries(PurchaseHeader, GLAccount[1], 118.88, 6.31);
        VerifyAmountsWithCreatedEntries(PurchaseHeader, GLAccount[2], 118.99, 9.71);
        VerifyAmountsWithCreatedEntries(PurchaseHeader, GLAccount[3], 118.39, 18.50);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckVATBaseAmountOnPurchaseInvoiceWithReverseVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLineReverseCharge: Record "Purchase Line";
        PurchaseLineNormalVAT: Record "Purchase Line";
        VATPostingSetupReverseChargeVAT: Record "VAT Posting Setup";
        VATPostingSetupNormalVAT: Record "VAT Posting Setup";
        VATIdentifier: Code[20];
    begin
        // [FEATURE] [Reverse Charge VAT] [Purchase] [Invoice]
        // [SCENARIO 397975] "VAT %" = 0 on purchase line with "VAT Calculation Type" = "Reverse Charge VAT"
        Initialize();
        VATIdentifier := LibraryUtility.GenerateGUID();
        UpdateVATTolerancePercentOnGLSetup(5);

        CreatePurchHeaderWithVATBaseDisc(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);
        PurchaseHeader.Validate("VAT Base Discount %", 2);
        PurchaseHeader.Modify(true);

        // [GIVEN] VAT Posting Setup[2] = "Normal VAT", "VAT %" = 21, "VAT Identifier" = "V21"
        // [GIVEN] VAT Posting Setup[2] = "Reverse Charge VAT", "VAT %" = 21, "VAT Identifier" = "V21"
        CreateVATPostingSetupWithBusPostGroup(
          VATPostingSetupNormalVAT, VATPostingSetupNormalVAT."VAT Calculation Type"::"Normal VAT",
          PurchaseHeader."VAT Bus. Posting Group", 21, VATIdentifier);

        CreateVATPostingSetupWithBusPostGroup(
          VATPostingSetupReverseChargeVAT, VATPostingSetupReverseChargeVAT."VAT Calculation Type"::"Reverse Charge VAT",
          PurchaseHeader."VAT Bus. Posting Group", 21, VATIdentifier);

        // [GIVEN] Invoice's line[1] with "VAT Posting Setup"[1] and Amount = 50
        CreatePurchaseLineWithVATPostingSetup(PurchaseLineNormalVAT, PurchaseHeader, VATPostingSetupNormalVAT);
        PurchaseLineNormalVAT.Validate("Direct Unit Cost", 50);
        PurchaseLineNormalVAT.Modify(true);

        // [GIVEN] Invoice's line[2] with "VAT Posting Setup"[2] and Amount = 50
        CreatePurchaseLineWithVATPostingSetup(PurchaseLineReverseCharge, PurchaseHeader, VATPostingSetupReverseChargeVAT);
        PurchaseLineReverseCharge.Validate("Direct Unit Cost", 50);
        PurchaseLineReverseCharge.Modify(true);

        // [WHEN] Validate "VAT Posting Group" line[2]
        // [THEN] "VAT %" = 0 on line[2]
        PurchaseLineReverseCharge.TestField("VAT %", 0);

        // Bonus: Verify "VAT Base Amount" calculation is correct.
        PurchaseHeader.Find();

        PurchaseHeader.Validate("VAT Base Discount %", 0);
        VerifyVATBaseAmountOnPurchaseLine(PurchaseLineNormalVAT, 50);
        VerifyVATBaseAmountOnPurchaseLine(PurchaseLineReverseCharge, 50);

        PurchaseHeader.Validate("VAT Base Discount %", 1);
        VerifyVATBaseAmountOnPurchaseLine(PurchaseLineNormalVAT, 49.5);
        VerifyVATBaseAmountOnPurchaseLine(PurchaseLineReverseCharge, 50);

        PurchaseHeader.Validate("VAT Base Discount %", 2);
        VerifyVATBaseAmountOnPurchaseLine(PurchaseLineNormalVAT, 49);
        VerifyVATBaseAmountOnPurchaseLine(PurchaseLineReverseCharge, 50);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckVATBaseAmountOnSalesInvoiceWithReverseVAT()
    var
        SalesHeader: Record "Sales Header";
        SalesLineReverseCharge: Record "Sales Line";
        SalesLineNormalVAT: Record "Sales Line";
        VATPostingSetupReverseChargeVAT: Record "VAT Posting Setup";
        VATPostingSetupNormalVAT: Record "VAT Posting Setup";
        VATIdentifier: Code[20];
    begin
        // [FEATURE] [Reverse Charge VAT] [Sales] [Invoice]
        // [SCENARIO 397975] "VAT %" = 0 on sales line with "VAT Calculation Type" = "Reverse Charge VAT"
        Initialize();
        VATIdentifier := LibraryUtility.GenerateGUID();
        UpdateVATTolerancePercentOnGLSetup(5);

        CreateSalesHeaderWithVATBaseDisc(SalesHeader, SalesHeader."Document Type"::Invoice);
        SalesHeader.Validate("VAT Base Discount %", 2);
        SalesHeader.Modify(true);

        // [GIVEN] VAT Posting Setup[2] = "Normal VAT", "VAT %" = 21, "VAT Identifier" = "V21"
        // [GIVEN] VAT Posting Setup[2] = "Reverse Charge VAT", "VAT %" = 21, "VAT Identifier" = "V21"
        CreateVATPostingSetupWithBusPostGroup(
          VATPostingSetupNormalVAT, VATPostingSetupNormalVAT."VAT Calculation Type"::"Normal VAT",
          SalesHeader."VAT Bus. Posting Group", 21, VATIdentifier);

        CreateVATPostingSetupWithBusPostGroup(
          VATPostingSetupReverseChargeVAT, VATPostingSetupReverseChargeVAT."VAT Calculation Type"::"Reverse Charge VAT",
          SalesHeader."VAT Bus. Posting Group", 21, VATIdentifier);

        // [GIVEN] Invoice's line[1] with "VAT Posting Setup"[1] and Amount = 50
        CreateSalesLineWithVATPostingSetup(SalesLineNormalVAT, SalesHeader, VATPostingSetupNormalVAT);
        SalesLineNormalVAT.Validate("Unit Price", 50);
        SalesLineNormalVAT.Modify(true);

        // [GIVEN] Invoice's line[2] with "VAT Posting Setup"[2] and Amount = 50
        CreateSalesLineWithVATPostingSetup(SalesLineReverseCharge, SalesHeader, VATPostingSetupReverseChargeVAT);
        SalesLineReverseCharge.Validate("Unit Price", 50);
        SalesLineReverseCharge.Modify(true);

        // [WHEN] Validate "VAT Posting Group" line[2]
        // [THEN] "VAT %" = 0 on line[2]
        SalesLineReverseCharge.TestField("VAT %", 0);

        // Bonus: Verify "VAT Base Amount" calculation is correct.
        SalesHeader.Find();

        SalesHeader.Validate("VAT Base Discount %", 0);
        VerifyVATBaseAmountOnSalesLine(SalesLineNormalVAT, 50);
        VerifyVATBaseAmountOnSalesLine(SalesLineReverseCharge, 50);

        SalesHeader.Validate("VAT Base Discount %", 1);
        VerifyVATBaseAmountOnSalesLine(SalesLineNormalVAT, 49.5);
        VerifyVATBaseAmountOnSalesLine(SalesLineReverseCharge, 50);

        SalesHeader.Validate("VAT Base Discount %", 2);
        VerifyVATBaseAmountOnSalesLine(SalesLineNormalVAT, 49);
        VerifyVATBaseAmountOnSalesLine(SalesLineReverseCharge, 50);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseDocumentTotalsOnSequenceOfUpdateLineAmountAndNonDeductibleVATPercent()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPercent: Decimal;
        VATAmount: Decimal;
        LineAmount: Decimal;
        VATBaseAmount: Decimal;
        NonDeductibleVATAmount: Decimal;
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Document Totals] [VAT] [VAT Base Discount]
        // [SCENARIO 423110] System considers "VAT Base Discount %" and "Non Deductible VAT %" when calculates document totals and posts the document.
        Initialize();

        UpdateVATTolerancePercentOnGLSetup(10);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), 1);
        PurchaseLine.Validate("Direct Unit Cost", 1000);
        PurchaseLine.Modify();

        LineAmount := PurchaseLine."Direct Unit Cost";
        VATPercent := PurchaseLine."VAT %";
        VATAmount := Round(PurchaseLine."Direct Unit Cost" * VATPercent / 100);

        SetNonDeductibleVATAndVATBaseDiscountOnPurchaseInvoice(PurchaseHeader, PurchaseLine, LineAmount, VATBaseAmount, VATAmount, NonDeductibleVATAmount);

        PurchaseHeader.Find();
        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        VerifySumOfGLEntryAmountForGLAccount(InvoiceNo, PurchaseLine."No.", LineAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseDocumentUpdateDeferralCodeAndNonDeductibleVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DeferralTemplate: Record "Deferral Template";
        VATPercent: Decimal;
        VATAmount: Decimal;
        LineAmount: Decimal;
        VATBaseAmount: Decimal;
        NonDeductibleVATAmount: Decimal;
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Document Totals] [VAT] [Deferral]
        // [SCENARIO 423110] System considers "VAT Base Discount %" and "Non Deductible VAT %" when calculates document totals and posts the document with Deferral setup.
        Initialize();

        UpdateVATTolerancePercentOnGLSetup(10);

        LibraryERM.CreateDeferralTemplate(
          DeferralTemplate, DeferralTemplate."Calc. Method"::"Equal per Period", DeferralTemplate."Start Date"::"Beginning of Next Period",
          LibraryRandom.RandIntInRange(3, 7));

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), 1);
        PurchaseLine.Validate("Direct Unit Cost", 1000);
        PurchaseLine.Validate("Deferral Code", DeferralTemplate."Deferral Code");
        PurchaseLine.Modify();

        LineAmount := PurchaseLine."Direct Unit Cost";
        VATPercent := PurchaseLine."VAT %";
        VATAmount := Round(PurchaseLine."Direct Unit Cost" * VATPercent / 100);

        SetNonDeductibleVATAndVATBaseDiscountOnPurchaseInvoice(PurchaseHeader, PurchaseLine, LineAmount, VATBaseAmount, VATAmount, NonDeductibleVATAmount);

        PurchaseHeader.Find();
        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        VerifySumOfGLEntryAmountForGLAccount(InvoiceNo, DeferralTemplate."Deferral Account", VATBaseAmount + NonDeductibleVATAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceLCYWithJob()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        JobTask: Record "Job Task";
        VATBase: Decimal;
    begin
        // [FEATURE] [Purchase] [VAT] [Job] [Invoice]
        // [SCENARIO 421859] Job ledger entries amounts include non deductible VAT for invoice in LCY
        Initialize();

        // [GIVEN] G/L Account "X" with Normal VAT and Non Deductible VAT 60%
        CreateVATSetupWithGLAccount(
          VATPostingSetup, GLAccount, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandIntInRange(20, 40));

        // [WHEN] Create and post purchase invoice for account "X" with job, VATBase = 1126
        CreateAndPostPurchaseInvoiceForJob(VATPostingSetup, '', GLAccount, VATBase, JobTask);

        // [THEN] Job ledger entry has Unit Cost = 1126
        VerifyJobLedgerEntryLCY(JobTask, VATBase);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceCurrencyWithJob()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        JobTask: Record "Job Task";
        VATBase: Decimal;
    begin
        // [FEATURE] [Purchase] [VAT] [Job] [Invoice]
        // [SCENARIO 421859] Job ledger entries amounts include non deductible VAT for invoice in currency
        Initialize();

        // [GIVEN] G/L Account "X" with Normal VAT and Non Deductible VAT 60%
        CreateVATSetupWithGLAccount(
          VATPostingSetup, GLAccount, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandIntInRange(20, 40));

        // [WHEN] Create and post purchase invoice for account "X" with job, Currency Code = "YYY", VATBase = 1126
        CreateAndPostPurchaseInvoiceForJob(VATPostingSetup, LibraryERM.CreateCurrencyWithRandomExchRates(), GLAccount, VATBase, JobTask);

        // [THEN] Job ledger entry has Unit Cost = 1126
        VerifyJobLedgerEntry(JobTask, VATBase);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseCrMemoLCYWithJob()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        JobTask: Record "Job Task";
        VATBase: Decimal;
    begin
        // [FEATURE] [Purchase] [VAT] [Job] [Credit Memo]
        // [SCENARIO 421859] Job ledger entries amounts include non deductible VAT for credit memo in LCY
        Initialize();

        // [GIVEN] G/L Account "X" with Normal VAT and Non Deductible VAT 60%
        CreateVATSetupWithGLAccount(
          VATPostingSetup, GLAccount, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandIntInRange(20, 40));

        // [WHEN] Create and post purchase credit memo for account "X" with job, VATBase = 1126
        CreateAndPostPurchaseCrMemoForJob(VATPostingSetup, GLAccount, VATBase, JobTask);

        // [THEN] Job ledger entry has Unit Cost = 1126
        VerifyJobLedgerEntryLCY(JobTask, VATBase);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseCrMemoCurrencyWithJob()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        JobTask: Record "Job Task";
        VATBase: Decimal;
    begin
        // [FEATURE] [Purchase] [VAT] [Job] [Credit Memo]
        // [SCENARIO 421859] Job ledger entries amounts include non deductible VAT for credit memo in currency
        Initialize();

        // [GIVEN] G/L Account "X" with Normal VAT and Non Deductible VAT 60%
        CreateVATSetupWithGLAccount(
          VATPostingSetup, GLAccount, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandIntInRange(20, 40));

        // [WHEN] Create and post purchase credit memo for account "X" with job, Currency Code = "YYY", VATBase = 1126
        CreateAndPostPurchaseCrMemoForJob(VATPostingSetup, GLAccount, VATBase, JobTask);

        // [THEN] Job ledger entry has Unit Cost = 1126
        VerifyJobLedgerEntry(JobTask, VATBase);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseStatisticsVATBaseCheckModalPageHandler')]
    [Scope('OnPrem')]
    procedure CheckVATAmountOnPurchInvoiceWithSingleLineReverseVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLineReverseCharge: Record "Purchase Line";
        VATPostingSetupReverseChargeVAT: Record "VAT Posting Setup";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [FEATURE] [Reverse Charge VAT] [Purchase Invoice] [VAT Base Discount]
        // [SCENARIO 432547] If there is discount according to Payment Terms, it should be used while calculating Reverse Charge VAT
        Initialize();

        // [GIVEN] Purchase Invoice Header for new Vendor with 2% VAT Base Discount
        CreatePurchHeaderWithVATBaseDisc(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);

        // [GIVEN] Purchase Invoice Line for G/L Account with 19% Reverse Charge VAT and "Direct unit Cost" = 1000
        CreatePurchaseLineWithVATType(
          PurchaseLineReverseCharge, PurchaseHeader,
          PurchaseLineReverseCharge."VAT Calculation Type"::"Reverse Charge VAT");

        VATPostingSetupReverseChargeVAT.Get(
          PurchaseLineReverseCharge."VAT Bus. Posting Group", PurchaseLineReverseCharge."VAT Prod. Posting Group");

        // [WHEN] When open invoice's statistics
        PurchaseHeader.TestField("VAT Base Discount %");
        LibraryVariableStorage.Enqueue(GetLoweredVATBase(PurchaseLineReverseCharge."Direct Unit Cost", PurchaseHeader."VAT Base Discount %"));
        PurchaseInvoice.OpenView();
        PurchaseInvoice.Filter.SetFilter("No.", PurchaseHeader."No.");
        PurchaseInvoice.Statistics.Invoke();

        // [THEN] "VAT Base (Lowered)" = 980 on VAT amount lines.
        // verified in handler
        LibraryVariableStorage.AssertEmpty();
    end;

    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseStatisticsVATBaseCheckModalPageHandler')]
    [Scope('OnPrem')]
    procedure CheckVATAmountOnPurchInvoiceWithSingleLineNormalVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLineReverseCharge: Record "Purchase Line";
        VATPostingSetupReverseChargeVAT: Record "VAT Posting Setup";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [FEATURE] [Normal VAT] [Purchase Invoice] [VAT Base Discount]
        // [SCENARIO 432547] "VAT Base (Lowered)" must reflect "VAT Base Discount %" calculating Normal VAT
        Initialize();

        // [GIVEN] Purchase Invoice Header for new Vendor with 2% VAT Base Discount
        CreatePurchHeaderWithVATBaseDisc(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);

        // [GIVEN] Purchase Invoice Line for G/L Account with 19% Normal VAT and "Direct unit Cost" = 1000
        CreatePurchaseLineWithVATType(
          PurchaseLineReverseCharge, PurchaseHeader,
          PurchaseLineReverseCharge."VAT Calculation Type"::"Normal VAT");

        VATPostingSetupReverseChargeVAT.Get(
          PurchaseLineReverseCharge."VAT Bus. Posting Group", PurchaseLineReverseCharge."VAT Prod. Posting Group");

        // [WHEN] When open invoice's statistics
        PurchaseHeader.TestField("VAT Base Discount %");
        LibraryVariableStorage.Enqueue(GetLoweredVATBase(PurchaseLineReverseCharge."Direct Unit Cost", PurchaseHeader."VAT Base Discount %"));
        PurchaseInvoice.OpenView();
        PurchaseInvoice.Filter.SetFilter("No.", PurchaseHeader."No.");
        PurchaseInvoice.Statistics.Invoke();

        // [THEN] "VAT Base (Lowered)" = 980 on VAT amount lines.
        // verified in handler
        LibraryVariableStorage.AssertEmpty();
    end;
#endif

    [Test]
    [HandlerFunctions('PurchaseStatisticsVATBaseCheckPageHandler')]
    [Scope('OnPrem')]
    procedure CheckVATAmtOnPurchInvoiceWithSingleLineReverseVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLineReverseCharge: Record "Purchase Line";
        VATPostingSetupReverseChargeVAT: Record "VAT Posting Setup";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [FEATURE] [Reverse Charge VAT] [Purchase Invoice] [VAT Base Discount]
        // [SCENARIO 432547] If there is discount according to Payment Terms, it should be used while calculating Reverse Charge VAT
        Initialize();

        // [GIVEN] Purchase Invoice Header for new Vendor with 2% VAT Base Discount
        CreatePurchHeaderWithVATBaseDisc(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);

        // [GIVEN] Purchase Invoice Line for G/L Account with 19% Reverse Charge VAT and "Direct unit Cost" = 1000
        CreatePurchaseLineWithVATType(
          PurchaseLineReverseCharge, PurchaseHeader,
          PurchaseLineReverseCharge."VAT Calculation Type"::"Reverse Charge VAT");

        VATPostingSetupReverseChargeVAT.Get(
          PurchaseLineReverseCharge."VAT Bus. Posting Group", PurchaseLineReverseCharge."VAT Prod. Posting Group");

        // [WHEN] When open invoice's statistics
        PurchaseHeader.TestField("VAT Base Discount %");
        LibraryVariableStorage.Enqueue(GetLoweredVATBase(PurchaseLineReverseCharge."Direct Unit Cost", PurchaseHeader."VAT Base Discount %"));
        PurchaseInvoice.OpenView();
        PurchaseInvoice.Filter.SetFilter("No.", PurchaseHeader."No.");
        PurchaseInvoice.PurchaseStatistics.Invoke();

        // [THEN] "VAT Base (Lowered)" = 980 on VAT amount lines.
        // verified in handler
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PurchaseStatisticsVATBaseCheckPageHandler')]
    [Scope('OnPrem')]
    procedure CheckVATAmtOnPurchInvoiceWithSingleLineNormalVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLineReverseCharge: Record "Purchase Line";
        VATPostingSetupReverseChargeVAT: Record "VAT Posting Setup";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [FEATURE] [Normal VAT] [Purchase Invoice] [VAT Base Discount]
        // [SCENARIO 432547] "VAT Base (Lowered)" must reflect "VAT Base Discount %" calculating Normal VAT
        Initialize();

        // [GIVEN] Purchase Invoice Header for new Vendor with 2% VAT Base Discount
        CreatePurchHeaderWithVATBaseDisc(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);

        // [GIVEN] Purchase Invoice Line for G/L Account with 19% Normal VAT and "Direct unit Cost" = 1000
        CreatePurchaseLineWithVATType(
          PurchaseLineReverseCharge, PurchaseHeader,
          PurchaseLineReverseCharge."VAT Calculation Type"::"Normal VAT");

        VATPostingSetupReverseChargeVAT.Get(
          PurchaseLineReverseCharge."VAT Bus. Posting Group", PurchaseLineReverseCharge."VAT Prod. Posting Group");

        // [WHEN] When open invoice's statistics
        PurchaseHeader.TestField("VAT Base Discount %");
        LibraryVariableStorage.Enqueue(GetLoweredVATBase(PurchaseLineReverseCharge."Direct Unit Cost", PurchaseHeader."VAT Base Discount %"));
        PurchaseInvoice.OpenView();
        PurchaseInvoice.Filter.SetFilter("No.", PurchaseHeader."No.");
        PurchaseInvoice.PurchaseStatistics.Invoke();

        // [THEN] "VAT Base (Lowered)" = 980 on VAT amount lines.
        // verified in handler
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATBaseAmountOnVATEntriesWithVATBaseDiscountAnd100PctNonDeductibleVATReverseChargeVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        DocumentNo: Code[20];
        ExpectedVATBase: Decimal;
        ExpectedVATAmount: Decimal;
    begin
        // [FEATURE] [Reverse Charge VAT] [Purchase Invoice] [VAT Base Discount] [Non-Deductible VAT]
        // [SCENARIO 429879] "VAT Base Discount %" must be reflected in Base amount on posted VAT Entries when "Non Deductible VAT %" = 100% for "VAT Calculation Type" = "Reverse Charge VAT"
        Initialize();

        // [GIVEN] Purchase Invoice Header for new Vendor with 2% VAT Base Discount
        CreatePurchHeaderWithVATBaseDisc(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);

        // [GIVEN] Purchase Invoice Line for G/L Account with 19% Reverse Charge VAT, 100% Non-Deductible VAT and "Direct unit Cost" = 1000
        CreateVATPostingSetupWithBusPostGroup(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT",
          PurchaseHeader."VAT Bus. Posting Group", LibraryRandom.RandIntInRange(10, 30), LibraryUtility.GenerateGUID());

        LibraryBEHelper.CreateGLAccount(GLAccount, VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase, 100);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccount."No.", 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(1000, 10000));
        PurchaseLine.Modify(true);

        // [WHEN] Post Purchase Invoice
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] "VAT Base Amount" = Round(Amount * (1 - "VAT Base Discount %" / 100));
        // [THEN] VATAmount = Round("VAT Base Amount" * "VAT %" / 100);
        // [THEN] NonDeductible-VATAmount = Round("VAT Base Amount" * "Nod Deductible VAT %" / 100);
        // [THEN] Final-VATBaseAmount = "VAT Base Amount" + "NonDeductible-VATAmount"
        // [THEN] Final-VATAmount = VATAmount - "NonDeductible-VATAmount"
        ExpectedVATBase := Round(PurchaseLine."Direct Unit Cost" * (1 - PurchaseHeader."VAT Base Discount %" / 100));
        ExpectedVATAmount := Round(ExpectedVATBase * VATPostingSetup."VAT %" / 100);
        ExpectedVATBase := ExpectedVATBase + Round(ExpectedVATAmount * GLAccount."% Non deductible VAT" / 100);
        ExpectedVATAmount := ExpectedVATAmount - Round(ExpectedVATAmount * GLAccount."% Non deductible VAT" / 100);
        VerifyAmountsWithCreatedVATEntries(DocumentNo, GLAccount, ExpectedVATBase, ExpectedVATAmount);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATBaseAmountOnVATEntriesWithVATBaseDiscountAnd100PctNonDeductibleVATNormalVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        DocumentNo: Code[20];
        ExpectedVATBase: Decimal;
        ExpectedVATAmount: Decimal;
    begin
        // [FEATURE] [Normal VAT] [Purchase Invoice] [VAT Base Discount] [Non-Deductible VAT]
        // [SCENARIO 429879] "VAT Base Discount %" must be reflected in Base amount on posted VAT Entries when "Non Deductible VAT %" = 100% for "VAT Calculation Type" = "Normal VAT"
        Initialize();

        // [GIVEN] Purchase Invoice Header for new Vendor with 2% VAT Base Discount
        CreatePurchHeaderWithVATBaseDisc(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);

        // [GIVEN] Purchase Invoice Line for G/L Account with 19% Normal VAT, 100% Non-Deductible VAT and "Direct unit Cost" = 1000
        CreateVATPostingSetupWithBusPostGroup(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT",
          PurchaseHeader."VAT Bus. Posting Group", LibraryRandom.RandIntInRange(10, 30), LibraryUtility.GenerateGUID());

        LibraryBEHelper.CreateGLAccount(GLAccount, VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase, 100);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccount."No.", 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(1000, 10000));
        PurchaseLine.Modify(true);

        // [WHEN] Post Purchase Invoice
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] "VAT Base Amount" = Round(Amount * (1 - "VAT Base Discount %" / 100));
        // [THEN] VATAmount = Round("VAT Base Amount" * "VAT %" / 100);
        // [THEN] NonDeductible-VATAmount = Round("VAT Base Amount" * "Nod Deductible VAT %" / 100);
        // [THEN] Final-VATBaseAmount = "VAT Base Amount" + "NonDeductible-VATAmount"
        // [THEN] Final-VATAmount = VATAmount - "NonDeductible-VATAmount"
        ExpectedVATBase := Round(PurchaseLine."Direct Unit Cost" * (1 - PurchaseHeader."VAT Base Discount %" / 100));
        ExpectedVATAmount := Round(ExpectedVATBase * VATPostingSetup."VAT %" / 100);
        ExpectedVATBase := ExpectedVATBase + Round(ExpectedVATAmount * GLAccount."% Non deductible VAT" / 100);
        ExpectedVATAmount := ExpectedVATAmount - Round(ExpectedVATAmount * GLAccount."% Non deductible VAT" / 100);
        VerifyAmountsWithCreatedVATEntries(DocumentNo, GLAccount, ExpectedVATBase, ExpectedVATAmount);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATBaseAmountOnVATEntriesWithVATBaseDiscountAnd70PctNonDeductibleVATReverseChargeVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        DocumentNo: Code[20];
        ExpectedVATBase: Decimal;
        ExpectedVATAmount: Decimal;
    begin
        // [FEATURE] [Reverse Charge VAT] [Purchase Invoice] [VAT Base Discount] [Non-Deductible VAT]
        // [SCENARIO 429879] "VAT Base Discount %" must be reflected in Base amount on posted VAT Entries when "Non Deductible VAT %" = 70% for "VAT Calculation Type" = "Reverse Charge VAT"
        Initialize();

        // [GIVEN] Purchase Invoice Header for new Vendor with 2% VAT Base Discount
        CreatePurchHeaderWithVATBaseDisc(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);

        // [GIVEN] Purchase Invoice Line for G/L Account with 19% Reverse Charge VAT, 70% Non-Deductible VAT and "Direct unit Cost" = 1000
        CreateVATPostingSetupWithBusPostGroup(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT",
          PurchaseHeader."VAT Bus. Posting Group", 17, LibraryUtility.GenerateGUID());

        LibraryBEHelper.CreateGLAccount(GLAccount, VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase, 70);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccount."No.", 1);
        PurchaseLine.Validate("Direct Unit Cost", 1117);
        PurchaseLine.Modify(true);

        // [WHEN] Post Purchase Invoice
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] "VAT Base Amount" = Round(Amount * (1 - "VAT Base Discount %" / 100));
        // [THEN] VATAmount = Round("VAT Base Amount" * "VAT %" / 100);
        // [THEN] NonDeductible-VATAmount = Round("VAT Base Amount" * "Nod Deductible VAT %" / 100);
        // [THEN] Final-VATBaseAmount = "VAT Base Amount" + "NonDeductible-VATAmount"
        // [THEN] Final-VATAmount = VATAmount - "NonDeductible-VATAmount"
        ExpectedVATBase := Round(PurchaseLine."Direct Unit Cost" * (1 - PurchaseHeader."VAT Base Discount %" / 100));
        ExpectedVATAmount := Round(ExpectedVATBase * VATPostingSetup."VAT %" / 100);
        ExpectedVATBase := ExpectedVATBase + Round(ExpectedVATAmount * GLAccount."% Non deductible VAT" / 100);
        ExpectedVATAmount := ExpectedVATAmount - Round(ExpectedVATAmount * GLAccount."% Non deductible VAT" / 100);
        // SLICE 426635: Rounding issue on Reverse Charge VAT
        VerifyAmountsWithCreatedVATEntries(DocumentNo, GLAccount, ExpectedVATBase + 0.01, ExpectedVATAmount - 0.01);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATBaseAmountOnVATEntriesWithVATBaseDiscountAnd70PctNonDeductibleVATNormalVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        DocumentNo: Code[20];
        ExpectedVATBase: Decimal;
        ExpectedVATAmount: Decimal;
    begin
        // [FEATURE] [Normal VAT] [Purchase Invoice] [VAT Base Discount] [Non-Deductible VAT]
        // [SCENARIO 429879] "VAT Base Discount %" must be reflected in Base amount on posted VAT Entries when "Non Deductible VAT %" = 70% for "VAT Calculation Type" = "Normal VAT"
        Initialize();

        // [GIVEN] Purchase Invoice Header for new Vendor with 2% VAT Base Discount
        CreatePurchHeaderWithVATBaseDisc(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);

        // [GIVEN] Purchase Invoice Line for G/L Account with 19% Normal VAT, 70% Non-Deductible VAT and "Direct unit Cost" = 1000
        CreateVATPostingSetupWithBusPostGroup(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT",
          PurchaseHeader."VAT Bus. Posting Group", 17, LibraryUtility.GenerateGUID());

        LibraryBEHelper.CreateGLAccount(GLAccount, VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase, 70);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccount."No.", 1);
        PurchaseLine.Validate("Direct Unit Cost", 1117);
        PurchaseLine.Modify(true);

        // [WHEN] Post Purchase Invoice
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] "VAT Base Amount" = Round(Amount * (1 - "VAT Base Discount %" / 100));
        // [THEN] VATAmount = Round("VAT Base Amount" * "VAT %" / 100);
        // [THEN] NonDeductible-VATAmount = Round("VAT Base Amount" * "Nod Deductible VAT %" / 100);
        // [THEN] Final-VATBaseAmount = "VAT Base Amount" + "NonDeductible-VATAmount"
        // [THEN] Final-VATAmount = VATAmount - "NonDeductible-VATAmount"
        ExpectedVATBase := Round(PurchaseLine."Direct Unit Cost" * (1 - PurchaseHeader."VAT Base Discount %" / 100));
        ExpectedVATAmount := Round(ExpectedVATBase * VATPostingSetup."VAT %" / 100);
        ExpectedVATBase := ExpectedVATBase + Round(ExpectedVATAmount * GLAccount."% Non deductible VAT" / 100);
        ExpectedVATAmount := ExpectedVATAmount - Round(ExpectedVATAmount * GLAccount."% Non deductible VAT" / 100);
        VerifyAmountsWithCreatedVATEntries(DocumentNo, GLAccount, ExpectedVATBase, ExpectedVATAmount);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure AutomaticStandardPurchaseLinesWithNonDeductibleVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        StandardPurchaseCode: Record "Standard Purchase Code";
        StandardPurchaseLine: Record "Standard Purchase Line";
        StandardVendorPurchaseCode: Record "Standard Vendor Purchase Code";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        VendorList: TestPage "Vendor List";
        PurchaseOrder: TestPage "Purchase Order";
        NonDeductibleVAT: Decimal;
    begin
        // [FEATURE] [Standard Lines]
        // [SCENARIO 467195] Stan can use the automatic standard purcahse lines functionality with Non-Deductible VAT

        Initialize();
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandInt(30));
        NonDeductibleVAT := LibraryRandom.RandInt(99);
        // [GIVEN] G/L Account "X" with "% Nondeductible VAT"
        CreateGLAccount(GLAccount, VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase, NonDeductibleVAT);
        // [GIVEN] Standard purchase code "Y" with one line that has "No." = "X"
        LibraryPurchase.CreateStandardPurchaseCode(StandardPurchaseCode);
        LibraryPurchase.CreateStandardPurchaseLine(StandardPurchaseLine, StandardPurchaseCode.Code);
        StandardPurchaseLine.Validate(Type, StandardPurchaseLine.Type::"G/L Account");
        StandardPurchaseLine.Validate("No.", GLAccount."No.");
        StandardPurchaseLine.Modify();
        // [GIVEN] Vendor "V" with standard purchase code "Y" that has "Insert Rec. Lines On Orders" = Automatic
        Vendor.Get(LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        LibraryPurchase.CreateVendorPurchaseCode(StandardVendorPurchaseCode, Vendor."No.", StandardPurchaseCode.Code);
        StandardVendorPurchaseCode.Validate(
          "Insert Rec. Lines On Orders", StandardVendorPurchaseCode."Insert Rec. Lines On Orders"::Automatic);
        StandardVendorPurchaseCode.Modify(true);

        // [GIVEN] Vendor List on vendor "V" record
        VendorList.OpenEdit();
        VendorList.Filter.SetFilter("No.", Vendor."No.");

        // [GIVEN] Perform page action: New Purchase Document -> Purchase Order
        PurchaseOrder.Trap();
        VendorList.NewPurchaseOrder.Invoke();

        // [WHEN] Activate "Buy-from Vendor No." field
        PurchaseOrder."Buy-from Vendor No.".Activate();

        PurchaseOrder.Close();
        VendorList.Close();
        // [THEN] Purchase line with G/L Account "X" and Non-Deductible VAT is inserted
        PurchaseHeader.SetRange("Buy-from Vendor No.", Vendor."No.");
        PurchaseHeader.FindFirst();
        LibraryPurchase.FindFirstPurchLine(PurchaseLine, PurchaseHeader);
        PurchaseLine.TestField(Type, PurchaseLine.Type::"G/L Account");
        PurchaseLine.TestField("No.", GLAccount."No.");
        PurchaseLine.TestField("Non Deductible VAT %", GLAccount."% Non deductible VAT");
    end;

    [Test]
    procedure PostedPurchCrMemoTotalsWithNonDedVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PuchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        DocumentTotals: Codeunit "Document Totals";
        NonDeductibleVAT: Decimal;
        AmountWithoutVAT: Decimal;
        VATAmount: Decimal;
        ActualVATAmount: Decimal;
        NonDeductibleVATAmount: Decimal;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 486771] Totals in the posted purchase credit memo with the Non-Deductible VAT are correct

        Initialize();
        // [GIVEN] VAT Posting Setup with "VAT %" = 21
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandInt(30));
        NonDeductibleVAT := LibraryRandom.RandInt(99);
        AmountWithoutVAT := LibraryRandom.RandIntInRange(100, 1000);
        VATAmount := Round(AmountWithoutVAT * (VATPostingSetup."VAT %" / 100), 0.01);
        NonDeductibleVATAmount := Round(VATAmount * (NonDeductibleVAT / 100), 0.01);
        // [GIVEN] G/L Account "X" with "% Nondeductible VAT" = 50
        CreateGLAccount(GLAccount, VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase, NonDeductibleVAT);

        // [GIVEN] Posted purchase Credit Memo with G/L Account "X", Amount = 1000, Original VAT Amount = 210
        CreatePurchaseCrMemoHeader(PurchaseHeader, VATPostingSetup."VAT Bus. Posting Group");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, "Purchase Line Type"::"G/L Account", GLAccount."No.", 1);
        PurchaseLine.Validate("Direct Unit Cost", AmountWithoutVAT);
        PurchaseLine.Modify();
        PuchCrMemoHdr.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
        PuchCrMemoHdr.CalcFields(Amount);
        PurchCrMemoLine.SetRange("Document No.", PuchCrMemoHdr."No.");
        PurchCrMemoLine.FindFirst();

        // [WHEN] Calculate totals for the posted purchase credit memo
        DocumentTotals.CalculatePostedPurchCreditMemoTotals(PuchCrMemoHdr, ActualVATAmount, PurchCrMemoLine);

        // [THEN] VAT Amount = 210 * 0.5 = 105
        Assert.AreEqual(VATAmount - NonDeductibleVATAmount, ActualVATAmount, 'Tota VAT Amount is not correct');

        // [THEN] Amount = 1000 + 105 = 1105
        PuchCrMemoHdr.TestField(Amount, AmountWithoutVAT + NonDeductibleVATAmount);
    end;

    [Test]
    procedure ShipmentMethodCodeBlankValidationIssue()
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO 562928] "Shipment Method Code" OnValidate trigger issue on "Purchase Header"
        Initialize();

        // [GIVEN] Create vendor with Shipment Method Code
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Shipment Method Code", CreateShipmentMethod());
        Vendor.Modify(true);

        // [GIVEN] Create Purchase Order
        LibraryPurchase.CreatePurchaseOrderForVendorNo(PurchaseHeader, Vendor."No.");

        // [GIVEN] Open Purchase Order
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GoToRecord(PurchaseHeader);

        // [THEN] Verify Purchase Order has Shiment Method Code
        PurchaseOrder."Shipment Method Code".AssertEquals(Vendor."Shipment Method Code");

        // [THEN] Verify no validation issue when "Shipment Method Code" set to blank  
        PurchaseOrder."Shipment Method Code".SetValue('');
        PurchaseOrder.Close();
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Non-Deductible VAT");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Non-Deductible VAT");

        LibraryERMCountryData.SetZeroVATSetupForPurchInvRoundingAccounts();
        LibrarySetupStorage.SaveGeneralLedgerSetup();
        LibrarySetupStorage.SavePurchasesSetup();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Non-Deductible VAT");
    end;

    local procedure CreateVATPostingSetupWithBusPostGroup(var VATPostingSetup: Record "VAT Posting Setup"; VATCalculationType: Enum "Tax Calculation Type"; VATBusinessPostingGroupCode: Code[20]; VATPercent: Decimal; VATIdentifier: Code[20])
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroupCode, VATProductPostingGroup.Code);
        VATPostingSetup."VAT %" := VATPercent;
        VATPostingSetup.Validate("Purchase VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup."Reverse Chrg. VAT Acc." := VATPostingSetup."Purchase VAT Account";
        VATPostingSetup."VAT Calculation Type" := VATCalculationType;
        VATPostingSetup."VAT Identifier" := VATIdentifier;
        VATPostingSetup.Modify();
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VATCalculationType: Enum "Tax Calculation Type")
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATCalculationType, LibraryRandom.RandIntInRange(10, 30));
        VATPostingSetup."Reverse Chrg. VAT Acc." := LibraryERM.CreateGLAccountNo();
        VATPostingSetup.Modify();
    end;

    local procedure CreateGLAccount(var GLAccount: Record "G/L Account"; VATPostingSetup: Record "VAT Posting Setup"; GenPostingType: Enum "General Posting Type"; NonDeductibleVAT: Integer)
    begin
        GLAccount.Get(LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GenPostingType));
        GLAccount."% Non deductible VAT" := NonDeductibleVAT;
        GLAccount.Modify();
    end;

    local procedure CreateVATSetupWithGLAccount(var VATPostingSetup: Record "VAT Posting Setup"; var GLAccount: Record "G/L Account"; VATCalculationType: Enum "Tax Calculation Type"; NonDedVATPct: Decimal)
    begin
        CreateVATPostingSetup(VATPostingSetup, VATCalculationType);
        CreateGLAccount(GLAccount, VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase, NonDedVATPct);
    end;

    local procedure ReverseChargeVAT(CurrencyCode: Code[10])
    var
        GenPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchLine: Record "Purchase Line";
        InvNo: Code[20];
        NonDedVATPct: Decimal;
    begin
        LibraryERM.FindGeneralPostingSetup(GenPostingSetup);
        NonDedVATPct := LibraryRandom.RandInt(100);
        FindUpdateRevChrgVATPostingSetup(
          VATPostingSetup, GenPostingSetup."Gen. Prod. Posting Group", NonDedVATPct);
        InvNo :=
          CreatePostPurchInvWithReverseChrgVATAcc(PurchLine, VATPostingSetup, GenPostingSetup."Gen. Bus. Posting Group", CurrencyCode);

        VerifyGLEntries(GenPostingSetup, VATPostingSetup, PurchLine, InvNo);
    end;

    local procedure UpdACYInGenLedgSetup(NewACYCode: Code[10]) OldACYCode: Code[10]
    var
        GenLedgSetup: Record "General Ledger Setup";
    begin
        GenLedgSetup.Get();
        OldACYCode := GenLedgSetup."Additional Reporting Currency";
        GenLedgSetup."Additional Reporting Currency" := NewACYCode;
        GenLedgSetup.Modify(true);
    end;

    local procedure UpdUnrealVATInGenLedgSetup(NewUnrealVAT: Boolean) OldUnrealVAT: Boolean
    var
        GenLedgSetup: Record "General Ledger Setup";
    begin
        GenLedgSetup.Get();
        OldUnrealVAT := GenLedgSetup."Unrealized VAT";
        GenLedgSetup.Validate("Unrealized VAT", NewUnrealVAT);
        GenLedgSetup.Modify(true);
    end;

    local procedure FindUpdateRevChrgVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; GenProdPostGroupCode: Code[20]; NonDedVATPct: Decimal)
    var
        GLAccNo: Code[20];
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        GLAccNo :=
          CreateNonDedGLAccWithPostingGroups(GenProdPostGroupCode, VATPostingSetup."VAT Prod. Posting Group", NonDedVATPct);
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", GLAccNo);
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateVendWithPostingGroups(GenBusPostGroupCode: Code[20]; VATBusPostGroupCode: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(LibraryPurchase.CreateVendorWithBusPostingGroups(GenBusPostGroupCode, VATBusPostGroupCode));
        UpdateInvoiceRoundingAccountForVendor(Vendor."Vendor Posting Group", VATBusPostGroupCode);
        exit(Vendor."No.");
    end;

    local procedure CreateCurrencyAndExchangeRate(): Code[10]
    var
        GLAccount: Record "G/L Account";
        Currency: Record Currency;
        CurrencyExchRate: Record "Currency Exchange Rate";
    begin
        LibraryERM.FindGLAccount(GLAccount);

        LibraryERM.CreateCurrency(Currency);
        Currency.Validate("Residual Gains Account", GLAccount."No.");
        Currency.Validate("Residual Losses Account", Currency."Residual Gains Account");
        Currency.Validate("Realized G/L Gains Account", GLAccount."No.");
        Currency.Validate("Realized G/L Losses Account", Currency."Realized G/L Gains Account");
        Currency.Modify(true);

        // Create Currency Exchange Rate.
        LibraryERM.CreateExchRate(CurrencyExchRate, Currency.Code, WorkDate());
        CurrencyExchRate.Validate("Exchange Rate Amount", LibraryRandom.RandDec(100, 2));
        CurrencyExchRate.Validate(
          "Relational Exch. Rate Amount", CurrencyExchRate."Exchange Rate Amount" + LibraryRandom.RandDec(500, 2));
        CurrencyExchRate.Modify(true);
        exit(Currency.Code);
    end;

    local procedure CreateNonDedGLAccWithPostingGroups(GenProdPostGroupCode: Code[20]; VATProdPostGroupCode: Code[20]; NonDedVATRate: Decimal): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Prod. Posting Group", GenProdPostGroupCode);
        GLAccount.Validate("VAT Prod. Posting Group", VATProdPostGroupCode);
        GLAccount.Validate("% Non deductible VAT", NonDedVATRate);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreatePostPurchInvWithReverseChrgVATAcc(var PurchLine: Record "Purchase Line"; VATPostingSetup: Record "VAT Posting Setup"; GenBusPostGroupCode: Code[20]; CurrencyCode: Code[10]): Code[20]
    var
        PurchHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(
          PurchHeader, PurchHeader."Document Type"::Invoice,
          CreateVendWithPostingGroups(GenBusPostGroupCode, VATPostingSetup."VAT Bus. Posting Group"));
        PurchHeader.Validate("Currency Code", CurrencyCode);
        PurchHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(
          PurchLine, PurchHeader, PurchLine.Type::"G/L Account", VATPostingSetup."Reverse Chrg. VAT Acc.", 1); // pass 1 for qty cause value is not important
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchLine.Modify(true);

        exit(LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true));
    end;

    local procedure CreatePostPurchInvWithHundredPctVATND(GenPostingSetup: Record "General Posting Setup"; VATPostingSetup: Record "VAT Posting Setup"): Code[20]
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        GLAccNo: Code[20];
    begin
        LibraryPurchase.CreatePurchHeader(
          PurchHeader, PurchHeader."Document Type"::Invoice,
          CreateVendWithPostingGroups(GenPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group"));

        GLAccNo :=
          CreateNonDedGLAccWithPostingGroups(GenPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group",
            100); // pass 100 for Non Ded. VAT Rate
        LibraryPurchase.CreatePurchaseLine(
          PurchLine, PurchHeader, PurchLine.Type::"G/L Account", GLAccNo, 1); // pass 1 for qty cause value is not important
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchLine.Modify(true);

        exit(LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true));
    end;

    local procedure CalcAmountsFromPurchLine(var VATAmount: Decimal; var VATNDAmount: Decimal; PurchLine: Record "Purchase Line"; VATPct: Decimal; Amount: Decimal)
    begin
        VATAmount := Amount * VATPct / 100;
        VATNDAmount := Round(VATAmount * PurchLine."Non Deductible VAT %" / 100);
        VATAmount := Round(VATAmount);
    end;

    local procedure ExchangeAmtFCYToLCY(PurchInvHeader: Record "Purch. Inv. Header"; AmountFCY: Decimal): Decimal
    begin
        exit(
          Round(
            LibraryERM.ConvertCurrency(AmountFCY, PurchInvHeader."Currency Code", '', PurchInvHeader."Posting Date"),
            LibraryERM.GetAmountRoundingPrecision()));
    end;

    local procedure GetLoweredVATAmount(DirectUnitCost: Decimal; VATDiscPct: Decimal; VATPct: Decimal): Decimal
    begin
        exit(Round(GetLoweredVATBase(DirectUnitCost, VATDiscPct) * VATPct / 100));
    end;

    local procedure GetLoweredVATBase(DirectUnitCost: Decimal; VATDiscPct: Decimal): Decimal
    begin
        exit(Round(DirectUnitCost * (1 - (VATDiscPct / 100))));
    end;

    local procedure CreatePurchaseLineWithVATType(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; VATType: Enum "Tax Calculation Type")
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        CreateVATPostingSetupWithBusPostGroup(
          VATPostingSetup,
          VATType,
          PurchaseHeader."VAT Bus. Posting Group",
          LibraryRandom.RandInt(30),
          LibraryUtility.GenerateGUID());

        CreatePurchaseLineWithVATPostingSetup(PurchaseLine, PurchaseHeader, VATPostingSetup);
    end;

    local procedure CreatePurchaseLineWithVATPostingSetup(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; VATPostingSetup: Record "VAT Posting Setup")
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryBEHelper.CreateGLAccount(GLAccount, VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase, 0);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccount."No.", 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(1000, 10000));
        PurchaseLine.Modify();
    end;

    local procedure CreateSalesLineWithVATPostingSetup(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; VATPostingSetup: Record "VAT Posting Setup")
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryBEHelper.CreateGLAccount(GLAccount, VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase, 0);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccount."No.", 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandIntInRange(1000, 10000));
        SalesLine.Modify();
    end;

    local procedure CreatePurchaseOrderWithDiscountAndReverseChargeVAT(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);

        CreatePurchaseInvoiceHeader(PurchaseHeader, VATBusinessPostingGroup.Code);
        PurchaseHeader."VAT Base Discount %" := LibraryRandom.RandInt(10);
        PurchaseHeader.Modify();

        CreatePurchaseLineWithVATType(
          PurchaseLine, PurchaseHeader,
          PurchaseLine."VAT Calculation Type"::"Reverse Charge VAT");
    end;

    local procedure OpenPurchInvStatistics(DocumentNo: Code[20])
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
    begin
        PostedPurchaseInvoice.OpenView();
        PurchInvHeader.Get(DocumentNo);
        PostedPurchaseInvoice.GotoRecord(PurchInvHeader);
        PostedPurchaseInvoice.Statistics.Invoke();
    end;

    local procedure OpenPurchCrMemoStatistics(DocumentNo: Code[20])
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PostedPurchaseCrMemo: TestPage "Posted Purchase Credit Memo";
    begin
        PostedPurchaseCrMemo.OpenView();
        PurchCrMemoHdr.Get(DocumentNo);
        PostedPurchaseCrMemo.GotoRecord(PurchCrMemoHdr);
        PostedPurchaseCrMemo.Statistics.Invoke();
    end;

    local procedure CreatePurchHeaderWithVATBaseDisc(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type")
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        Vendor: Record Vendor;
        PaymentTerms: Record "Payment Terms";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, true);

        Vendor.Get(LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATBusinessPostingGroup.Code));
        Vendor.Validate("Payment Terms Code", PaymentTerms.Code);
        Vendor.Modify(true);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, Vendor."No.");

        GeneralLedgerSetup.Get();
        PurchaseHeader.Validate("VAT Base Discount %", LibraryRandom.RandInt(GeneralLedgerSetup."VAT Tolerance %"));
        PurchaseHeader.Modify(true);
    end;

    local procedure CreateSalesHeaderWithVATBaseDisc(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type")
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, true);

        Customer.Get(LibrarySales.CreateCustomerWithVATBusPostingGroup(VATBusinessPostingGroup.Code));
        Customer.Validate("Payment Terms Code", PaymentTerms.Code);
        Customer.Modify(true);

        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, Customer."No.");

        GeneralLedgerSetup.Get();
        SalesHeader.Validate("VAT Base Discount %", LibraryRandom.RandInt(GeneralLedgerSetup."VAT Tolerance %"));
        SalesHeader.Modify(true);
    end;

    local procedure CreateAndPostPurchaseInvoice(VATPostingSetup: Record "VAT Posting Setup"; CurrencyCode: Code[10]; GLAccount: Record "G/L Account"; var VATBase: Decimal; var VATAmount: Decimal; var NonDedVATAmount: Decimal): Code[20]
    var
        DirectUnitCost: Decimal;
    begin
        DirectUnitCost := LibraryRandom.RandDecInRange(1000, 2000, 2);
        CalculateVATAmounts(VATBase, VATAmount, NonDedVATAmount, DirectUnitCost, VATPostingSetup."VAT %", GLAccount."% Non deductible VAT");
        exit(CreateAndPostPurchaseInvoice(VATPostingSetup, CurrencyCode, GLAccount, DirectUnitCost));
    end;

    local procedure CreateAndPostPurchaseInvoiceWithFCY(VATPostingSetup: Record "VAT Posting Setup"; CurrencyCode: Code[10]; GLAccount: Record "G/L Account"; var VATBase: Decimal; var VATAmount: Decimal; var NonDedVATAmount: Decimal; var VATBaseLCY: Decimal; var VATAmountLCY: Decimal; var NonDedVATAmountLCY: Decimal): Code[20]
    var
        DirectUnitCost, DirectUnitCostLCY : Decimal;
    begin
        DirectUnitCost := LibraryRandom.RandDecInRange(1000, 2000, 2);
        CalculateVATAmounts(VATBase, VATAmount, NonDedVATAmount, DirectUnitCost, VATPostingSetup."VAT %", GLAccount."% Non deductible VAT");
        DirectUnitCostLCY := Round(LibraryERM.ConvertCurrency(DirectUnitCost, CurrencyCode, '', WorkDate()));
        CalculateVATAmounts(VATBaseLCY, VATAmountLCY, NonDedVATAmountLCY, DirectUnitCostLCY, VATPostingSetup."VAT %", GLAccount."% Non deductible VAT");
        exit(CreateAndPostPurchaseInvoice(VATPostingSetup, CurrencyCode, GLAccount, DirectUnitCost));
    end;

    local procedure CreateAndPostPurchaseInvoiceWithFCYAndACY(VATPostingSetup: Record "VAT Posting Setup"; CurrencyCode: Code[10]; GLAccount: Record "G/L Account"; var VATBase: Decimal; var VATAmount: Decimal; var NonDedVATAmount: Decimal; var VATBaseLCY: Decimal; var VATAmountLCY: Decimal; var NonDedVATAmountLCY: Decimal; var VATBaseACY: Decimal; var VATAmountACY: Decimal; var NonDedVATAmountACY: Decimal): Code[20]
    var
        DirectUnitCost, DirectUnitCostLCY : Decimal;
    begin
        DirectUnitCost := LibraryRandom.RandDecInRange(1000, 2000, 2);
        CalculateVATAmounts(VATBase, VATAmount, NonDedVATAmount, DirectUnitCost, VATPostingSetup."VAT %", GLAccount."% Non deductible VAT");
        DirectUnitCostLCY := Round(LibraryERM.ConvertCurrency(DirectUnitCost, CurrencyCode, '', WorkDate()));
        CalculateVATAmounts(VATBaseLCY, VATAmountLCY, NonDedVATAmountLCY, DirectUnitCostLCY, VATPostingSetup."VAT %", GLAccount."% Non deductible VAT");
        VATBaseACY := Round(LibraryERM.ConvertCurrency(VATBaseLCY, '', LibraryERM.GetAddReportingCurrency(), WorkDate()));
        VATAmountACY := Round(LibraryERM.ConvertCurrency(VATAmountLCY, '', LibraryERM.GetAddReportingCurrency(), WorkDate()));
        NonDedVATAmountACY := Round(LibraryERM.ConvertCurrency(NonDedVATAmountLCY, '', LibraryERM.GetAddReportingCurrency(), WorkDate()));
        exit(CreateAndPostPurchaseInvoice(VATPostingSetup, CurrencyCode, GLAccount, DirectUnitCost));
    end;

    local procedure CreateAndPostPurchaseInvoice(VATPostingSetup: Record "VAT Posting Setup"; CurrencyCode: Code[10]; GLAccount: Record "G/L Account"; DirectUnitCost: Decimal): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseInvoiceHeader(PurchaseHeader, VATPostingSetup."VAT Bus. Posting Group");
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccount."No.", 1);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CalculateVATAmounts(var VATBase: Decimal; var VATAmount: Decimal; var NonDedVATAmount: Decimal; DirectUnitCost: Decimal; VATPct: Decimal; NDVATPct: Decimal)
    begin
        VATAmount := Round(DirectUnitCost * VATPct / 100);
        NonDedVATAmount := Round(VATAmount * NDVATPct / 100);
        VATAmount -= NonDedVATAmount;
        VATBase := DirectUnitCost + NonDedVATAmount;
    end;

    local procedure CreateAndPostPurchaseInvoiceForJob(VATPostingSetup: Record "VAT Posting Setup"; CurrencyCode: Code[10]; GLAccount: Record "G/L Account"; var VATBase: Decimal; var JobTask: Record "Job Task"): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Job: Record Job;
        CurrencyExchRate: Record "Currency Exchange Rate";
        DirectUnitCost: Decimal;
        VATAmount: Decimal;
        NonDedVATAmount: Decimal;
    begin
        DirectUnitCost := LibraryRandom.RandDecInRange(1000, 2000, 2);
        VATAmount := Round(DirectUnitCost * VATPostingSetup."VAT %" / 100);
        NonDedVATAmount := Round(VATAmount * GLAccount."% Non deductible VAT" / 100);
        VATAmount -= NonDedVATAmount;
        VATBase := DirectUnitCost + NonDedVATAmount;
        LibraryJob.CreateJob(Job);
        Job.Validate("Apply Usage Link", false);
        Job.Modify(true);
        LibraryJob.CreateJobTask(Job, JobTask);

        CreatePurchaseInvoiceHeader(PurchaseHeader, VATPostingSetup."VAT Bus. Posting Group");
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccount."No.", 1);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Validate("Job No.", Job."No.");
        PurchaseLine.Validate("Job Task No.", JobTask."Job Task No.");
        PurchaseLine.Modify(true);

        if CurrencyCode <> '' then
            VATBase :=
                CurrencyExchRate.ExchangeAmtFCYToLCY(
                    PurchaseHeader."Posting Date",
                    CurrencyCode,
                    VATBase,
                    PurchaseHeader."Currency Factor");
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateAndPostPurchaseCrMemoForJob(VATPostingSetup: Record "VAT Posting Setup"; GLAccount: Record "G/L Account"; var VATBase: Decimal; var JobTask: Record "Job Task"): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Job: Record Job;
        DirectUnitCost: Decimal;
        VATAmount: Decimal;
        NonDedVATAmount: Decimal;
    begin
        DirectUnitCost := LibraryRandom.RandDecInRange(1000, 2000, 2);
        VATAmount := Round(DirectUnitCost * VATPostingSetup."VAT %" / 100);
        NonDedVATAmount := Round(VATAmount * GLAccount."% Non deductible VAT" / 100);
        VATAmount -= NonDedVATAmount;
        VATBase := DirectUnitCost + NonDedVATAmount;
        LibraryJob.CreateJob(Job);
        Job.Validate("Apply Usage Link", false);
        Job.Modify(true);
        LibraryJob.CreateJobTask(Job, JobTask);

        CreatePurchaseCrMemoHeader(PurchaseHeader, VATPostingSetup."VAT Bus. Posting Group");

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccount."No.", 1);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Validate("Job No.", Job."No.");
        PurchaseLine.Validate("Job Task No.", JobTask."Job Task No.");
        PurchaseLine.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreatePurchaseInvoiceHeader(var PurchaseHeader: Record "Purchase Header"; VATBusPostingGroupCode: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
            LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATBusPostingGroupCode));
    end;

    local procedure CreatePurchaseCrMemoHeader(var PurchaseHeader: Record "Purchase Header"; VATBusPostingGroupCode: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo",
            LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATBusPostingGroupCode));
    end;

    local procedure CreatePurchaseItemLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; VATPostingSetup: Record "VAT Posting Setup")
    var
        Item: Record Item;
    begin
        LibraryBEHelper.CreateItem(Item, VATPostingSetup);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1000, 2000, 2));
        PurchaseLine.Validate("Non Deductible VAT %", LibraryRandom.RandIntInRange(10, 30));
        PurchaseLine.Modify();
    end;

    local procedure CreatePurchInvoiceWithNonDeductibleVAT(var PurchaseHeader: Record "Purchase Header"; VATPostingSetup: Record "VAT Posting Setup"; Amount: Decimal; NonDedVATPct: Integer)
    var
        GLAccount: Record "G/L Account";
        PurchaseLine: Record "Purchase Line";
    begin
        CreateGLAccount(GLAccount, VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase, NonDedVATPct);
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
          LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccount."No.", 1);
        PurchaseLine.Validate("Direct Unit Cost", Amount);
        PurchaseLine.Modify();
    end;

    local procedure CreatePurchInvoiceWithDeferralAndNonDedVAT(var PurchaseHeader: Record "Purchase Header"; VATPostingSetup: Record "VAT Posting Setup"; DeferralTemplateCode: Code[10]): Decimal
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        PurchaseHeader.Validate("Posting Date", CalcDate('<-CM>', WorkDate()));
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
          LibraryInventory.CreateItemNoWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"),
          LibraryRandom.RandIntInRange(10, 100));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(10, 100));
        PurchaseLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        PurchaseLine.Validate("Non Deductible VAT %", LibraryRandom.RandIntInRange(10, 50));
        PurchaseLine.Validate("Deferral Code", DeferralTemplateCode);
        PurchaseLine.Modify(true);
        exit(PurchaseLine.GetDeferralAmount());
    end;

    local procedure CreateCopyVATPostingSetup(var VATPostingSetupNew: Record "VAT Posting Setup"; VATPostingSetup: Record "VAT Posting Setup")
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        VATPostingSetupNew := VATPostingSetup;
        VATPostingSetupNew."VAT Prod. Posting Group" := VATProductPostingGroup.Code;
        VATPostingSetupNew."VAT Identifier" := VATProductPostingGroup.Code;
        VATPostingSetupNew.Insert();
    end;

    local procedure CreateCopyPurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; VATPostingSetup: Record "VAT Posting Setup")
    var
        VATPostingSetup2: Record "VAT Posting Setup";
    begin
        CreateCopyVATPostingSetup(VATPostingSetup2, VATPostingSetup);
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type, PurchaseLine."No.", 1);
        PurchaseLine.Validate("VAT Prod. Posting Group", VATPostingSetup2."VAT Prod. Posting Group");
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 20, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateVATStatementLine(var VATStatementLine: Record "VAT Statement Line"; VATStatementName: Record "VAT Statement Name"; VATPostingSetup: Record "VAT Posting Setup"; AmountType: Enum "VAT Statement Line Amount Type"; InclNonDeductibleVAT: Boolean)
    begin
        LibraryERM.CreateVATStatementLine(VATStatementLine, VATStatementName."Statement Template Name", VATStatementName.Name);
        VATStatementLine.Validate(Type, VATStatementLine.Type::"VAT Entry Totaling");
        VATStatementLine.Validate("Amount Type", AmountType);
        VATStatementLine.Validate("Document Type", VATStatementLine."Document Type"::Invoice);
        VATStatementLine.Validate("Gen. Posting Type", VATStatementLine."Gen. Posting Type"::Purchase);
        VATStatementLine.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        VATStatementLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        VATStatementLine.Validate("Incl. Non Deductible VAT", InclNonDeductibleVAT);
        VATStatementLine.Modify(true);
    end;

    local procedure SetNonDeductibleVATAndVATBaseDiscountOnPurchaseInvoice(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var LineAmount: Decimal; var VATBaseAmount: Decimal; var VATAmount: Decimal; var NonDeductibleVATAmount: Decimal)
    var
        PurchaseInvoice: TestPage "Purchase Invoice";
        VATPercent: Decimal;
    begin
        VATPercent := PurchaseLine."VAT %";

        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.Filter.SetFilter("No.", PurchaseHeader."No.");
        PurchaseInvoice.PurchLines."Non Deductible VAT %".AssertEquals(0);

        PurchaseInvoice.PurchLines."Total Amount Excl. VAT".AssertEquals(LineAmount);
        PurchaseInvoice.PurchLines."Total VAT Amount".AssertEquals(VATAmount);
        PurchaseInvoice.PurchLines."Total Amount Incl. VAT".AssertEquals(LineAmount + VATAmount);

        PurchaseInvoice.PurchLines."Non Deductible VAT %".SetValue(30);

        CalcVATAmounts(PurchaseInvoice, VATPercent, LineAmount, VATBaseAmount, VATAmount, NonDeductibleVATAmount);

        PurchaseInvoice.PurchLines."Total Amount Excl. VAT".AssertEquals(LineAmount);
        PurchaseInvoice.PurchLines."Total VAT Amount".AssertEquals(VATAmount);
        PurchaseInvoice.PurchLines."Total Amount Incl. VAT".AssertEquals(LineAmount + VATAmount);

        PurchaseInvoice."VAT Base Discount %".SetValue(10);

        CalcVATAmounts(PurchaseInvoice, VATPercent, LineAmount, VATBaseAmount, VATAmount, NonDeductibleVATAmount);

        PurchaseInvoice.PurchLines."Total Amount Excl. VAT".AssertEquals(LineAmount);
        PurchaseInvoice.PurchLines."Total VAT Amount".AssertEquals(VATAmount);
        PurchaseInvoice.PurchLines."Total Amount Incl. VAT".AssertEquals(LineAmount + VATAmount);

        PurchaseInvoice.Close();
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.Filter.SetFilter("No.", PurchaseHeader."No.");

        PurchaseInvoice.PurchLines."Total Amount Excl. VAT".AssertEquals(LineAmount);
        PurchaseInvoice.PurchLines."Total VAT Amount".AssertEquals(VATAmount);
        PurchaseInvoice.PurchLines."Total Amount Incl. VAT".AssertEquals(LineAmount + VATAmount);
        PurchaseInvoice.Close();
    end;

    local procedure CalcVATAmounts(var PurchaseInvoice: TestPage "Purchase Invoice"; VATPercent: Decimal; var LineAmount: Decimal; var VATBaseAmount: Decimal; var VATAmount: Decimal; var NonDeductibleVATAmount: Decimal)
    begin
        LineAmount := PurchaseInvoice.PurchLines."Direct Unit Cost".AsDecimal();
        VATBaseAmount := Round(LineAmount * (1 - PurchaseInvoice."VAT Base Discount %".AsDecimal() / 100));
        VATAmount := Round(VATBaseAmount * VATPercent / 100);
        NonDeductibleVATAmount := Round(VATAmount * PurchaseInvoice.PurchLines."Non Deductible VAT %".AsDecimal() / 100);
        VATAmount -= NonDeductibleVATAmount;
        LineAmount += NonDeductibleVATAmount;
    end;

    local procedure CalcVATStatementAmount(var Base: Decimal; var Amount: Decimal; VATPostingSetup: Record "VAT Posting Setup"; InclNonDeductibleVAT: Boolean; UseAmtsInAddCurr: Boolean)
    var
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: array[2] of Record "VAT Statement Line";
        VATStatement: Report "VAT Statement";
        Selection: Enum "VAT Statement Report Selection";
        PeriodSelection: Enum "VAT Statement Report Period Selection";
        CorrectionValue: Decimal;
        NetAmountLCY: Decimal;
    begin
        LibraryERM.CreateVATStatementNameWithTemplate(VATStatementName);
        CreateVATStatementLine(
          VATStatementLine[1], VATStatementName, VATPostingSetup, VATStatementLine[1]."Amount Type"::Base, InclNonDeductibleVAT);
        CreateVATStatementLine(
          VATStatementLine[2], VATStatementName, VATPostingSetup, VATStatementLine[2]."Amount Type"::Amount, InclNonDeductibleVAT);

        Clear(VATStatement);
        VATStatement.InitializeRequest(
          VATStatementName, VATStatementLine[1], Selection::"Open and Closed", PeriodSelection::"Within Period", false, UseAmtsInAddCurr);
        VATStatement.CalcLineTotal(VATStatementLine[1], Base, CorrectionValue, NetAmountLCY, '', 0);
        VATStatement.CalcLineTotal(VATStatementLine[2], Amount, CorrectionValue, NetAmountLCY, '', 0);
    end;

    local procedure MockPurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; VATCalculationType: Enum "Tax Calculation Type"; VATPercent: Decimal; PurchaseAmount: Decimal)
    begin
        PurchaseLine.Init();
        PurchaseLine."Document Type" := PurchaseHeader."Document Type";
        PurchaseLine."Document No." := PurchaseHeader."No.";
        PurchaseLine."Line No." := LibraryUtility.GetNewRecNo(PurchaseLine, PurchaseLine.FieldNo("Line No."));
        PurchaseLine."VAT %" := VATPercent;
        PurchaseLine."VAT Calculation Type" := VATCalculationType;
        PurchaseLine.Amount := PurchaseAmount;
        PurchaseLine."Amount Including VAT" := PurchaseLine.Amount * (1 + (PurchaseLine."VAT %" / 100));
        PurchaseLine.Insert();
    end;

    local procedure SaveCalcAndPostVATSettlementReport(var VATPostingSetup: Record "VAT Posting Setup"; Post: Boolean): Code[20]
    var
        GLAccount: Record "G/L Account";
        CalcAndPostVATSettlement: Report "Calc. and Post VAT Settlement";
        TemplateName: Code[10];
        BatchName: Code[10];
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        Clear(CalcAndPostVATSettlement);

        LibraryERM.FindGenJnlTemplateAndBatch(TemplateName, BatchName);
        CalcAndPostVATSettlement.InitializeRequest(WorkDate(), WorkDate(), WorkDate(), TemplateName, BatchName, GLAccount."No.", true, Post);
        CalcAndPostVATSettlement.InitializeRequest2(false);
        Commit();
        CalcAndPostVATSettlement.SetTableView(VATPostingSetup);
        CalcAndPostVATSettlement.Run();

        exit(GLAccount."No.");
    end;

    local procedure SetupAmountsForNonVATPurchaseStat(var NonDeductibleVATPct: array[2] of Integer; var AmountWithoutVAT: array[2] of Decimal; var AmountWithoutVATAndDiscount: Decimal; var VATAmount: array[2] of Decimal; var NonDeductibleVATAmount: array[2] of Decimal; var LineDiscount: Integer; VATPct: Decimal)
    begin
        LineDiscount := LibraryRandom.RandIntInRange(5, 10);
        SetupAmountsForNonVATPurchaseStatOneLine(
          NonDeductibleVATPct, AmountWithoutVAT, AmountWithoutVATAndDiscount, VATAmount, NonDeductibleVATAmount,
          LibraryRandom.RandIntInRange(5, 10), LineDiscount, VATPct);
        NonDeductibleVATPct[2] := LibraryRandom.RandInt(99);
        AmountWithoutVAT[2] := LibraryRandom.RandIntInRange(100, 1000);
        VATAmount[2] := LibraryBEHelper.CalcPercentage(AmountWithoutVAT[2], VATPct, LibraryERM.GetAmountRoundingPrecision());
        NonDeductibleVATAmount[2] :=
          LibraryBEHelper.CalcPercentage(VATAmount[2], NonDeductibleVATPct[2], LibraryERM.GetAmountRoundingPrecision());
    end;

    local procedure SetupAmountsForNonVATPurchaseStatOneLine(var NonDeductibleVATPct: array[2] of Integer; var AmountWithoutVAT: array[2] of Decimal; var AmountWithoutVATAndDiscount: Decimal; var VATAmount: array[2] of Decimal; var NonDeductibleVATAmount: array[2] of Decimal; NonDedVATPct: Integer; LineDiscount: Integer; VATPct: Decimal)
    begin
        NonDeductibleVATPct[1] := NonDedVATPct;
        AmountWithoutVAT[1] := LibraryRandom.RandIntInRange(100, 1000);
        AmountWithoutVATAndDiscount :=
          LibraryBEHelper.CalcPercentageChange(AmountWithoutVAT[1], LineDiscount, LibraryERM.GetAmountRoundingPrecision(), false);
        VATAmount[1] := LibraryBEHelper.CalcPercentage(AmountWithoutVATAndDiscount, VATPct, LibraryERM.GetAmountRoundingPrecision());
        NonDeductibleVATAmount[1] :=
          LibraryBEHelper.CalcPercentage(VATAmount[1], NonDeductibleVATPct[1], LibraryERM.GetAmountRoundingPrecision());
    end;

    local procedure ConvertAmounts(var VATBaseTarget: Decimal; var VATAmountTarget: Decimal; var NonDedVATAmountTarget: Decimal; VATBaseSource: Decimal; VATAmountSource: Decimal; NonDedVATAmountSource: Decimal; CurrencyCodeSource: Code[10]; CurrencyCodeTarget: Code[10])
    begin
        VATBaseTarget := Round(LibraryERM.ConvertCurrency(VATBaseSource, CurrencyCodeSource, CurrencyCodeTarget, WorkDate()));
        VATAmountTarget := Round(LibraryERM.ConvertCurrency(VATAmountSource, CurrencyCodeSource, CurrencyCodeTarget, WorkDate()));
        NonDedVATAmountTarget := Round(LibraryERM.ConvertCurrency(NonDedVATAmountSource, CurrencyCodeSource, CurrencyCodeTarget, WorkDate()));
    end;

    local procedure FindVATEntry(var VATEntry: Record "VAT Entry"; VendorNo: Code[20]; DocumentNo: Code[20])
    begin
        VATEntry.SetRange(Type, VATEntry.Type::Purchase);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange("Bill-to/Pay-to No.", VendorNo);
        VATEntry.FindFirst();
    end;

    local procedure VerifyPurchInvStatLine(PurchaseInvoiceStatistics: TestPage "Purchase Invoice Statistics"; VATPct: Decimal; VATAmount: Decimal; AmountInclVAT: Decimal)
    begin
        PurchaseInvoiceStatistics.SubForm."VAT %".AssertEquals(VATPct);
        PurchaseInvoiceStatistics.SubForm."VAT Amount".AssertEquals(VATAmount);
        PurchaseInvoiceStatistics.SubForm."Amount Including VAT".AssertEquals(AmountInclVAT);
    end;

    local procedure VerifyPurchCrMemoStatLine(PurchaseCrMemoStatistics: TestPage "Purch. Credit Memo Statistics"; VATPct: Decimal; VATAmount: Decimal; AmountInclVAT: Decimal)
    begin
        PurchaseCrMemoStatistics.SubForm."VAT %".AssertEquals(VATPct);
        PurchaseCrMemoStatistics.SubForm."VAT Amount".AssertEquals(VATAmount);
        PurchaseCrMemoStatistics.SubForm."Amount Including VAT".AssertEquals(AmountInclVAT);
    end;

    local procedure UpdateInvoiceRoundingAccountForVendor(VendorPostingGroupCode: Code[20]; VATBusPostGroupCode: Code[20])
    var
        VendorPostingGroup: Record "Vendor Posting Group";
        GLAccount: Record "G/L Account";
    begin
        VendorPostingGroup.Get(VendorPostingGroupCode);
        GLAccount.Get(VendorPostingGroup."Invoice Rounding Account");
        GLAccount."VAT Bus. Posting Group" := VATBusPostGroupCode;
        GLAccount."VAT Prod. Posting Group" := FindZeroVATProdPostGroup(VATBusPostGroupCode);
        GLAccount.Modify(true);
    end;

    local procedure UpdateVATTolerancePercentOnGLSetup(VATTolerancePercent: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("VAT Tolerance %", VATTolerancePercent);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure FindZeroVATProdPostGroup(VATBusPostGroupCode: Code[20]): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.SetFilter("VAT Bus. Posting Group", VATBusPostGroupCode);
        VATPostingSetup.SetFilter("VAT Prod. Posting Group", '<>%1', '');
        VATPostingSetup.SetRange("VAT %", 0);
        VATPostingSetup.FindFirst();
        exit(VATPostingSetup."VAT Prod. Posting Group");
    end;

    local procedure EnqueueAmountsForPurchStatisticsHandler(NonDeductibleVATAmount: array[2] of Decimal; VATAmount: array[2] of Decimal; AmountWithoutVATAndDiscount: Decimal; AmountWithoutVAT2: Decimal; OneVATAmountLine: Boolean)
    begin
        LibraryVariableStorage.Enqueue(NonDeductibleVATAmount[1]);
        LibraryVariableStorage.Enqueue(NonDeductibleVATAmount[2]);
        LibraryVariableStorage.Enqueue(VATAmount[1]);
        LibraryVariableStorage.Enqueue(VATAmount[2]);
        LibraryVariableStorage.Enqueue(AmountWithoutVATAndDiscount);
        LibraryVariableStorage.Enqueue(AmountWithoutVAT2);
        LibraryVariableStorage.Enqueue(OneVATAmountLine);
    end;

    local procedure VerifyGLEntries(GeneralPostingSetup: Record "General Posting Setup"; VATPostingSetup: Record "VAT Posting Setup"; PurchLine: Record "Purchase Line"; InvNo: Code[20])
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        Amount: Decimal;
        AmountACY: Decimal;
        VATAmount: Decimal;
        VATAmountACY: Decimal;
        VATNDAmount: Decimal;
        VATNDAmountACY: Decimal;
    begin
        PurchInvHeader.SetRange("No.", InvNo);
        PurchInvHeader.FindLast();
        if PurchInvHeader."Currency Code" = '' then begin
            Amount := PurchLine.Amount;
            AmountACY := 0;
            VATAmountACY := 0;
            VATNDAmountACY := 0;
        end else begin
            AmountACY := PurchLine.Amount;
            CalcAmountsFromPurchLine(VATAmountACY, VATNDAmountACY, PurchLine, VATPostingSetup."VAT %", AmountACY);
            Amount := ExchangeAmtFCYToLCY(PurchInvHeader, AmountACY);
        end;
        CalcAmountsFromPurchLine(VATAmount, VATNDAmount, PurchLine, VATPostingSetup."VAT %", Amount);

        VerifyGLEntry(
          InvNo, PurchLine."No.", GeneralPostingSetup."Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group",
          Amount + VATNDAmount, AmountACY + VATNDAmountACY);
        VerifyGLEntry(
          InvNo, VATPostingSetup."Purchase VAT Account", '', '', VATAmount - VATNDAmount, VATAmountACY - VATNDAmountACY);
        VerifyGLEntry(
          InvNo, VATPostingSetup."Reverse Chrg. VAT Acc.", '', '', -VATAmount, -VATAmountACY);
    end;

    local procedure VerifyGLEntry(DocNo: Code[20]; GLAccNo: Code[20]; GenBusPostGroupCode: Code[20]; GenProdPostGroupCode: Code[20]; ExpectedAmount: Decimal; ExpectedAmountACY: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocNo);
        GLEntry.SetRange("G/L Account No.", GLAccNo);
        GLEntry.SetRange("Gen. Bus. Posting Group", GenBusPostGroupCode);
        GLEntry.SetRange("Gen. Prod. Posting Group", GenProdPostGroupCode);
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, ExpectedAmount);
        GLEntry.TestField("Additional-Currency Amount", ExpectedAmountACY);
    end;

    local procedure VerifyZeroGLEntry(DocNo: Code[20]; GLAccNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocNo);
        GLEntry.SetRange("G/L Account No.", GLAccNo);
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, 0);
    end;

    local procedure VerifyGLEntryAmount(GLAccNo: Code[20]; ExpectedAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("G/L Account No.", GLAccNo);
        GLEntry.FindFirst();
        Assert.AreEqual(ExpectedAmount, GLEntry.Amount, GLEntry.FieldCaption(Amount));
    end;

    local procedure VerifyVATEntriesWithReverseCharge(DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20]; LoweredVATReverseCharge: Decimal; LoweredVATNormalVAT: Decimal; LoweredVATBaseReverseCharge: Decimal; LoweredVATBaseNormalVAT: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange("Document Type", DocumentType);
        Assert.AreEqual(2, VATEntry.Count, VATEntry.TableCaption());

        VATEntry.FindSet();
        Assert.AreEqual(
          VATEntry."VAT Calculation Type"::"Normal VAT",
          VATEntry."VAT Calculation Type",
          VATEntry.FieldCaption("VAT Calculation Type"));
        Assert.AreEqual(LoweredVATNormalVAT, VATEntry.Amount, VATEntry.FieldCaption(Amount));
        Assert.AreEqual(LoweredVATBaseNormalVAT, VATEntry.Base, VATEntry.FieldCaption(Base));

        VATEntry.Next();
        Assert.AreEqual(
          VATEntry."VAT Calculation Type"::"Reverse Charge VAT",
          VATEntry."VAT Calculation Type",
          VATEntry.FieldCaption("VAT Calculation Type"));
        Assert.AreEqual(LoweredVATReverseCharge, VATEntry.Amount, VATEntry.FieldCaption(Amount));
        Assert.AreEqual(LoweredVATBaseReverseCharge, VATEntry.Base, VATEntry.FieldCaption(Base));
    end;

    local procedure VerifyPurchStatisticSubform(var PurchaseStatistics: TestPage "Purchase Statistics"; AmountWOVAT: Decimal; VATAmount: Decimal; NDVATAmount: Decimal)
    begin
        PurchaseStatistics.SubForm."VAT Base (Lowered)".AssertEquals(AmountWOVAT + NDVATAmount);
        PurchaseStatistics.SubForm."VAT Amount".AssertEquals(VATAmount - NDVATAmount);
        PurchaseStatistics.SubForm."Amount Including VAT".AssertEquals(AmountWOVAT + VATAmount);
        PurchaseStatistics.SubForm."Line Amount".AssertEquals(AmountWOVAT + NDVATAmount);
    end;

    local procedure VerifyPurchInvoiceStatisticSubform(var PurchaseInvoiceStatistics: TestPage "Purchase Invoice Statistics"; AmountWOVAT: Decimal; VATAmount: Decimal; NDVATAmount: Decimal)
    begin
        PurchaseInvoiceStatistics.SubForm."VAT Base (Lowered)".AssertEquals(AmountWOVAT + NDVATAmount);
        PurchaseInvoiceStatistics.SubForm."VAT Amount".AssertEquals(VATAmount - NDVATAmount);
        PurchaseInvoiceStatistics.SubForm."Amount Including VAT".AssertEquals(AmountWOVAT + VATAmount);
        PurchaseInvoiceStatistics.SubForm."Line Amount".AssertEquals(AmountWOVAT + NDVATAmount);
    end;

    local procedure VerifyVATAccAndRevChrgAccBalance(VATPostingSetup: Record "VAT Posting Setup"; ExpectedAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetFilter("G/L Account No.", '%1|%2', VATPostingSetup."Purchase VAT Account", VATPostingSetup."Reverse Chrg. VAT Acc.");
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::" ");
        GLEntry.CalcSums(Amount);
        GLEntry.TestField(Amount, ExpectedAmount);
    end;

    local procedure VerifyVATSettlementReportVATAmount(RowNo: Integer; Amount: Decimal)
    begin
        LibraryReportValidation.VerifyCellValueByRef('K', RowNo, 1, LibraryReportValidation.FormatDecimalValue(Amount));
    end;

    local procedure VerifyVATSettlementReportVATEntryRow(RowNo: Integer; DocumentNo: Code[20]; Base: Decimal; Amount: Decimal; NonDedAmount: Decimal)
    begin
        LibraryReportValidation.VerifyCellValueByRef('B', RowNo, 1, DocumentNo);
        LibraryReportValidation.VerifyCellValueByRef('H', RowNo, 1, LibraryReportValidation.FormatDecimalValue(Base));
        VerifyVATSettlementReportVATAmount(RowNo, Amount);
        LibraryReportValidation.VerifyCellValueByRef('V', RowNo, 1, LibraryReportValidation.FormatDecimalValue(NonDedAmount));
    end;

    local procedure VerifyVATSettlementReportVATSetupValues(RowNo: Integer; VATPostingSetup: Record "VAT Posting Setup")
    begin
        LibraryReportValidation.VerifyCellValueByRef('A', RowNo, 1, VATPostingSetup."VAT Bus. Posting Group");
        LibraryReportValidation.VerifyCellValueByRef('B', RowNo, 1, VATPostingSetup."VAT Prod. Posting Group");
    end;

    local procedure VerifyVATEntryLCYAndACYAmounts(VendorNo: Code[20]; DocumentNo: Code[20]; VATBase: Decimal; VATAmount: Decimal; NonDedVATAmount: Decimal; VATBaseACY: Decimal; VATAmountACY: Decimal; NonDedVATAmountACY: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        FindVATEntry(VATEntry, VendorNo, DocumentNo);
        VATEntry.TestField(Base, VATBase);
        VATEntry.TestField(Amount, VATAmount);
        VATEntry.TestField("Non Ded. VAT Amount", NonDedVATAmount);
        VATEntry.TestField("Additional-Currency Base", VATBaseACY);
        VATEntry.TestField("Additional-Currency Amount", VATAmountACY);
        VATEntry.TestField("Non Ded. Source Curr. VAT Amt.", NonDedVATAmountACY);
    end;

    local procedure VerifyVATStatementAmountsLCYAndACY(VATPostingSetup: Record "VAT Posting Setup"; ExpectedBase: Decimal; ExpectedAmount: Decimal; NonDedVATAmount: Decimal; ExpectedBaseACY: Decimal; ExpectedAmountACY: Decimal; NonDedVATAmountACY: Decimal)
    begin
        VerifyVATStatementAmounts(
          VATPostingSetup, ExpectedBase - NonDedVATAmount, ExpectedAmount + NonDedVATAmount, true, false);
        VerifyVATStatementAmounts(
          VATPostingSetup, ExpectedBaseACY - NonDedVATAmountACY, ExpectedAmountACY + NonDedVATAmountACY, true, true);
        VerifyVATStatementAmounts(VATPostingSetup, ExpectedBase, ExpectedAmount, false, false);
        VerifyVATStatementAmounts(VATPostingSetup, ExpectedBaseACY, ExpectedAmountACY, false, true);
    end;

    local procedure VerifyVATStatementAmounts(VATPostingSetup: Record "VAT Posting Setup"; ExpectedBase: Decimal; ExpectedAmount: Decimal; InclNonDeductibleVAT: Boolean; UseAmtsInAddCurr: Boolean)
    var
        ActualBase: Decimal;
        ActualAmount: Decimal;
    begin
        CalcVATStatementAmount(ActualBase, ActualAmount, VATPostingSetup, InclNonDeductibleVAT, UseAmtsInAddCurr);
        Assert.AreEqual(ExpectedBase, ActualBase, '');
        Assert.AreEqual(ExpectedAmount, ActualAmount, '');
    end;

    local procedure VerifyGLEntryDeferrals(DeferralAccountNo: Code[20]; DocNo: Code[20]; DeferredAmount: Decimal; CountOfPeriod: Integer)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("G/L Account No.", DeferralAccountNo);
        GLEntry.SetRange("Document No.", DocNo);
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Invoice);
        GLEntry.SetFilter(Amount, '<%1', 0);
        Assert.RecordCount(GLEntry, CountOfPeriod);
        GLEntry.CalcSums(Amount);
        GLEntry.TestField(Amount, -DeferredAmount);
    end;

    local procedure VerifyVATBaseAmountOnPurchaseLine(var PurchaseLine: Record "Purchase Line"; ExpectedVATBaseAmount: Decimal)
    begin
        PurchaseLine.Find();
        PurchaseLine.TestField("VAT Base Amount", ExpectedVATBaseAmount);
    end;

    local procedure VerifyVATBaseAmountOnSalesLine(var SalesLine: Record "Sales Line"; ExpectedVATBaseAmount: Decimal)
    begin
        SalesLine.Find();
        SalesLine.TestField("VAT Base Amount", ExpectedVATBaseAmount);
    end;

    local procedure CreateVendorNoWithVATPostingSetupAndPricesIncludingVATSetup(var VATPostingSetup: Record "VAT Posting Setup"; VATCalculationType: Enum "Tax Calculation Type"; PriceIncludingVAT: Boolean): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATCalculationType, LibraryRandom.RandInt(30));

        Vendor.Get(LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        Vendor.Validate("Prices Including VAT", PriceIncludingVAT);
        Vendor.Modify();
        exit(Vendor."No.");
    end;

    local procedure CreatePurchaseLineWithGLAccountAndVATPostingSetup(var PurchaseHeader: Record "Purchase Header"; var VATPostingSetup: Record "VAT Posting Setup"; var GLAccount: Record "G/L Account"; VATCalculationType: Enum "Tax Calculation Type"; Amount: Integer; VATPerc: Integer; NonDeductibVAT: Integer): Code[20]
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreateVATPostingSetupWithNewProdGroup(VATPostingSetup, VATPerc, VATCalculationType);
        CreateGLAccount(GLAccount, VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase, NonDeductibVAT);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccount."No.", 1);
        PurchaseLine.Validate("Direct Unit Cost", Amount);
        PurchaseLine.Modify();
    end;

    local procedure CreateVATPostingSetupWithNewProdGroup(var VATPostingSetup: Record "VAT Posting Setup"; VATPerc: Integer; VATCalculationType: Enum "Tax Calculation Type")
    var
        VATProdPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProdPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Bus. Posting Group", VATProdPostingGroup.Code);
        VATPostingSetup.Validate("VAT Calculation Type", VATCalculationType);
        VATPostingSetup.Validate("VAT %", VATPerc);
        VATPostingSetup.Validate("VAT Identifier",
          LibraryUtility.GenerateRandomCode(VATPostingSetup.FieldNo("VAT Identifier"), DATABASE::"VAT Posting Setup"));
        VATPostingSetup.Validate("Sales VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Purchase VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify();
    end;

    local procedure VerifyTotalAmountAndTotalVAT(PurchaseHeader: Record "Purchase Header"; ExpectedAmount: Decimal; ExpectedVAT: Decimal)
    var
        DocumentTotals: Codeunit "Document Totals";
        PurchaseLine: Record "Purchase Line";
        ZeroPurchaseLine: Record "Purchase Line";
        TotalPurchaseLine: Record "Purchase Line";
        VATAmount: Decimal;
        InvDiscAmt: Decimal;
        InvDiscPcs: Decimal;
    begin
        PurchaseLine.SetFilter(Type, '%1', PurchaseLine.Type::"G/L Account");
        PurchaseLine.SetFilter("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindSet();
        repeat
            DocumentTotals.PurchaseDeltaUpdateTotals(PurchaseLine, ZeroPurchaseLine, TotalPurchaseLine, VATAmount, InvDiscAmt, InvDiscPcs);
        until PurchaseLine.Next() = 0;

        Assert.AreEqual(ExpectedAmount, TotalPurchaseLine.Amount, 'Unexpected Total Amount');
        Assert.AreEqual(ExpectedVAT, VATAmount, 'Unexpected Total VAT');
    end;

    local procedure VerifyAmountsWithCreatedEntries(PurchaseHeader: Record "Purchase Header"; GLAccount: Record "G/L Account"; ExpectedAmount: Decimal; ExpectedVAT: Decimal)
    begin
        VerifyAmountsWithCreatedVATEntries(PurchaseHeader."Last Posting No.", GLAccount, ExpectedAmount, ExpectedVAT);
        VerifyAmountsWithCreatedGLEntries(PurchaseHeader."Last Posting No.", GLAccount, ExpectedAmount, ExpectedVAT);
    end;

    local procedure VerifyAmountsWithCreatedVATEntries(DocumentNo: Code[20]; GLAccount: Record "G/L Account"; ExpectedBaseAmount: Decimal; ExpectedVATAmount: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Invoice);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange("VAT Prod. Posting Group", GLAccount."VAT Prod. Posting Group");
        VATEntry.FindFirst();

        VATEntry.TestField(Base, ExpectedBaseAmount);
        VATEntry.TestField(Amount, ExpectedVATAmount);
    end;

    local procedure VerifyAmountsWithCreatedGLEntries(DocumentNo: Code[20]; GLAccount: Record "G/L Account"; ExpectedAmount: Decimal; ExpectedVAT: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Invoice);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccount."No.");
        GLEntry.FindFirst();

        GLEntry.TestField(Amount, ExpectedAmount);
        GLEntry.TestField("VAT Amount", ExpectedVAT);
    end;

    local procedure VerifySumOfGLEntryAmountForGLAccount(DocumentNo: Code[20]; GLAccountNo: Code[20]; ExpectedAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Invoice);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.SetFilter(Amount, '>0');
        GLEntry.CalcSums(Amount);
        GLEntry.TestField(Amount, ExpectedAmount);
    end;

    local procedure VerifyJobLedgerEntryLCY(JobTask: Record "Job Task"; ExpectedAmount: Decimal)
    var
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        JobLedgerEntry.SetRange("Job No.", JobTask."Job No.");
        JobLedgerEntry.SetRange("Job Task No.", JobTask."Job Task No.");
        JobLedgerEntry.FindLast();
        JobLedgerEntry.TestField("Unit Cost", ExpectedAmount);
        JobLedgerEntry.TestField("Total Cost", JobLedgerEntry.Quantity * JobLedgerEntry."Unit Cost");
    end;

    local procedure VerifyJobLedgerEntry(JobTask: Record "Job Task"; ExpectedAmount: Decimal)
    var
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        JobLedgerEntry.SetRange("Job No.", JobTask."Job No.");
        JobLedgerEntry.SetRange("Job Task No.", JobTask."Job Task No.");
        JobLedgerEntry.FindLast();
        Assert.AreNearlyEqual(ExpectedAmount, JobLedgerEntry."Unit Cost", 0.01, 'Invalid Unit Cost');
        Assert.AreNearlyEqual(JobLedgerEntry.Quantity * JobLedgerEntry."Unit Cost", JobLedgerEntry."Total Cost", 0.01, 'Invalid Total Cost');
    end;

    local procedure CreateShipmentMethod(): Code[10]
    var
        ShipmentMethod: Record "Shipment Method";
    begin
        ShipmentMethod.Init();
        ShipmentMethod.Code := LibraryUtility.GenerateRandomCode(ShipmentMethod.FieldNo(Code), Database::"Shipment Method");
        ShipmentMethod.Insert();
        exit(ShipmentMethod.Code);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseStatisticsModalPageHandler(var PurchaseStatistics: TestPage "Purchase Statistics")
    var
        NonDeductibleVATAmount: array[2] of Decimal;
        VATAmount: array[2] of Decimal;
        AmountWithoutVATAndDiscount1: Decimal;
        AmountWithoutVAT2: Decimal;
    begin
        NonDeductibleVATAmount[1] := LibraryVariableStorage.DequeueDecimal();
        NonDeductibleVATAmount[2] := LibraryVariableStorage.DequeueDecimal();
        VATAmount[1] := LibraryVariableStorage.DequeueDecimal();
        VATAmount[2] := LibraryVariableStorage.DequeueDecimal();
        AmountWithoutVATAndDiscount1 := LibraryVariableStorage.DequeueDecimal();
        AmountWithoutVAT2 := LibraryVariableStorage.DequeueDecimal();

        PurchaseStatistics.TotalAmount1.AssertEquals(
          AmountWithoutVATAndDiscount1 + AmountWithoutVAT2 + NonDeductibleVATAmount[1] + NonDeductibleVATAmount[2]);

        PurchaseStatistics.VATAmount.AssertEquals(VATAmount[1] + VATAmount[2] - NonDeductibleVATAmount[1] - NonDeductibleVATAmount[2]);

        PurchaseStatistics.TotalAmount2.AssertEquals(AmountWithoutVATAndDiscount1 + AmountWithoutVAT2 + VATAmount[1] + VATAmount[2]);

        if LibraryVariableStorage.DequeueBoolean() then
            VerifyPurchStatisticSubform(
              PurchaseStatistics,
              AmountWithoutVATAndDiscount1 + AmountWithoutVAT2,
              VATAmount[1] + VATAmount[2],
              NonDeductibleVATAmount[1] + NonDeductibleVATAmount[2])
        else begin
            PurchaseStatistics.SubForm.First();
            VerifyPurchStatisticSubform(
              PurchaseStatistics, AmountWithoutVATAndDiscount1, VATAmount[1], NonDeductibleVATAmount[1]);
            PurchaseStatistics.SubForm.Next();
            VerifyPurchStatisticSubform(
              PurchaseStatistics, AmountWithoutVAT2, VATAmount[2], NonDeductibleVATAmount[2]);
        end;
    end;

    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseStatisticsVATBaseCheckModalPageHandler(var PurchaseStatistics: TestPage "Purchase Statistics")
    begin
        Assert.AreEqual(
            LibraryVariableStorage.DequeueDecimal(), PurchaseStatistics.SubForm."VAT Base (Lowered)".AsDecimal(), '');
    end;
#endif

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchaseStatisticsPageHandler(var PurchaseStatistics: TestPage "Purchase Statistics")
    var
        NonDeductibleVATAmount: array[2] of Decimal;
        VATAmount: array[2] of Decimal;
        AmountWithoutVATAndDiscount1: Decimal;
        AmountWithoutVAT2: Decimal;
    begin
        NonDeductibleVATAmount[1] := LibraryVariableStorage.DequeueDecimal();
        NonDeductibleVATAmount[2] := LibraryVariableStorage.DequeueDecimal();
        VATAmount[1] := LibraryVariableStorage.DequeueDecimal();
        VATAmount[2] := LibraryVariableStorage.DequeueDecimal();
        AmountWithoutVATAndDiscount1 := LibraryVariableStorage.DequeueDecimal();
        AmountWithoutVAT2 := LibraryVariableStorage.DequeueDecimal();

        PurchaseStatistics.TotalAmount1.AssertEquals(
          AmountWithoutVATAndDiscount1 + AmountWithoutVAT2 + NonDeductibleVATAmount[1] + NonDeductibleVATAmount[2]);

        PurchaseStatistics.VATAmount.AssertEquals(VATAmount[1] + VATAmount[2] - NonDeductibleVATAmount[1] - NonDeductibleVATAmount[2]);

        PurchaseStatistics.TotalAmount2.AssertEquals(AmountWithoutVATAndDiscount1 + AmountWithoutVAT2 + VATAmount[1] + VATAmount[2]);

        if LibraryVariableStorage.DequeueBoolean() then
            VerifyPurchStatisticSubform(
              PurchaseStatistics,
              AmountWithoutVATAndDiscount1 + AmountWithoutVAT2,
              VATAmount[1] + VATAmount[2],
              NonDeductibleVATAmount[1] + NonDeductibleVATAmount[2])
        else begin
            PurchaseStatistics.SubForm.First();
            VerifyPurchStatisticSubform(
              PurchaseStatistics, AmountWithoutVATAndDiscount1, VATAmount[1], NonDeductibleVATAmount[1]);
            PurchaseStatistics.SubForm.Next();
            VerifyPurchStatisticSubform(
              PurchaseStatistics, AmountWithoutVAT2, VATAmount[2], NonDeductibleVATAmount[2]);
        end;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchaseStatisticsVATBaseCheckPageHandler(var PurchaseStatistics: TestPage "Purchase Statistics")
    begin
        Assert.AreEqual(
            LibraryVariableStorage.DequeueDecimal(), PurchaseStatistics.SubForm."VAT Base (Lowered)".AsDecimal(), '');
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchaseStatisticsModalPageHandler(var PurchaseInvoiceStatistics: TestPage "Purchase Invoice Statistics")
    var
        NonDeductibleVATAmount: array[2] of Decimal;
        VATAmount: array[2] of Decimal;
        AmountWithoutVATAndDiscount1: Decimal;
        AmountWithoutVAT2: Decimal;
    begin
        NonDeductibleVATAmount[1] := LibraryVariableStorage.DequeueDecimal();
        NonDeductibleVATAmount[2] := LibraryVariableStorage.DequeueDecimal();
        VATAmount[1] := LibraryVariableStorage.DequeueDecimal();
        VATAmount[2] := LibraryVariableStorage.DequeueDecimal();
        AmountWithoutVATAndDiscount1 := LibraryVariableStorage.DequeueDecimal();
        AmountWithoutVAT2 := LibraryVariableStorage.DequeueDecimal();

        PurchaseInvoiceStatistics.VendAmount.AssertEquals(
          AmountWithoutVATAndDiscount1 + AmountWithoutVAT2 + NonDeductibleVATAmount[1] + NonDeductibleVATAmount[2]);

        PurchaseInvoiceStatistics.VATAmount.AssertEquals(
          VATAmount[1] + VATAmount[2] - NonDeductibleVATAmount[1] - NonDeductibleVATAmount[2]);

        PurchaseInvoiceStatistics.AmountInclVAT.AssertEquals(
          AmountWithoutVATAndDiscount1 + AmountWithoutVAT2 + VATAmount[1] + VATAmount[2]);

        if LibraryVariableStorage.DequeueBoolean() then
            VerifyPurchInvoiceStatisticSubform(
              PurchaseInvoiceStatistics,
              AmountWithoutVATAndDiscount1 + AmountWithoutVAT2,
              VATAmount[1] + VATAmount[2],
              NonDeductibleVATAmount[1] + NonDeductibleVATAmount[2])
        else begin
            PurchaseInvoiceStatistics.SubForm.First();
            VerifyPurchInvoiceStatisticSubform(
              PurchaseInvoiceStatistics, AmountWithoutVATAndDiscount1, VATAmount[1], NonDeductibleVATAmount[1]);
            PurchaseInvoiceStatistics.SubForm.Next();
            VerifyPurchInvoiceStatisticSubform(
              PurchaseInvoiceStatistics, AmountWithoutVAT2, VATAmount[2], NonDeductibleVATAmount[2]);
        end;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHCalcAndPostVATSettlement(var CalcAndPostVATSettlement: TestRequestPage "Calc. and Post VAT Settlement")
    begin
        CalcAndPostVATSettlement.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;
}

