codeunit 134287 "Non-Deductible VAT Statistics"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Non-Deductible VAT] [Statistics]
    end;

    var
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryNonDeductibleVAT: Codeunit "Library - NonDeductible VAT";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        Assert: Codeunit Assert;
        isInitialized: Boolean;
        GLEntryConsistentErr: Label 'G/L Entry is inconsistent';

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseStatisticsChangeVATAmountModalPageHandler')]
    procedure NonDedVATAmountNotChangedWhenVATAmountChanged()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoicePage: TestPage "Purchase Invoice";
        MaxVATDifference: Decimal;
        VATAmount: Decimal;
        NonDeductibleVATAmount: Decimal;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 456471] Non-Deductible VAT Amount is not changed in statistics when Stan changes the VAT amount

        Initialize();
        MaxVATDifference := LibraryRandom.RandDecInDecimalRange(0.1, 1, 2);
        // [GIVEN] "Allow VAT Difference" is enabled in Purchases Setup
        // [GIVEN] "Max VAT Difference" is 0.01 in General Ledger Setup
        SetAllowVATDifference(MaxVATDifference);
        // [GIVEN] Normal VAT Posting Setup with "VAT %" = 20 and Non-Deductible VAT %" = 75
        LibraryNonDeductibleVAT.CreateNonDeductibleNormalVATPostingSetup(VATPostingSetup);
        // [GIVEN] Purchase invoice with amount = 100. VAT Amount = 20. Non-Deductible VAT Amount = 15
        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
            LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        LibraryPurchase.CreatePurchaseLineWithUnitCost(
            PurchaseLine, PurchaseHeader, LibraryInventory.CreateItemWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"),
            LibraryRandom.RandDec(100, 2), LibraryRandom.RandInt(100));
        NonDeductibleVATAmount := PurchaseLine."Non-Deductible VAT Amount";
        VATAmount := PurchaseLine."Amount Including VAT" - PurchaseLine.Amount - MaxVATDifference;
        LibraryVariableStorage.Enqueue(NonDeductibleVATAmount);
        LibraryVariableStorage.Enqueue(VATAmount);

        // [GIVEN] Open purchase invoice page
        PurchaseInvoicePage.OpenEdit();
        PurchaseInvoicePage.Filter.SetFilter("No.", PurchaseHeader."No.");
        // [GIVEN] Open statistics of the invoice
        PurchaseInvoicePage.Statistics.Invoke();

        // [WHEN] Set "VAT Amount" = 19.99
        // [THEN] "Non-Deductible VAT amount" remains 15 on statistics page
        // [THEN] "Deductible Amount" is 4.99
        // Called in PurchaseStatisticsModalPageHandler

        PurchaseLine.Find();
        // [THEN] "VAT Difference" is -0.01 in the purchase line
        PurchaseLine.TestField("VAT Difference", -MaxVATDifference);
        // [THEN] "Amount Including VAT" is 119.99 in the purchase line
        PurchaseLine.TestField("Amount Including VAT", PurchaseLine.Amount + VATAmount);
        // [THEN] "Non-Deductible VAT" is 15 in the purchase line
        PurchaseLine.TestField("Non-Deductible VAT Amount", NonDeductibleVATAmount);
        // [THEN] "Non-Deductible VAT Diff." is zero in the purchase line
        PurchaseLine.TestField("Non-Deductible VAT Diff.", 0);
        LibraryVariableStorage.AssertEmpty();
    end;
#endif

    [Test]
    [HandlerFunctions('PurchaseStatisticsChangeVATAmountPageHandler')]
    procedure NonDedVATAmtNotChangedWhenVATAmtChanged()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoicePage: TestPage "Purchase Invoice";
        MaxVATDifference: Decimal;
        VATAmount: Decimal;
        NonDeductibleVATAmount: Decimal;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 456471] Non-Deductible VAT Amount is not changed in statistics when Stan changes the VAT amount

        Initialize();
        MaxVATDifference := LibraryRandom.RandDecInDecimalRange(0.1, 1, 2);
        // [GIVEN] "Allow VAT Difference" is enabled in Purchases Setup
        // [GIVEN] "Max VAT Difference" is 0.01 in General Ledger Setup
        SetAllowVATDifference(MaxVATDifference);
        // [GIVEN] Normal VAT Posting Setup with "VAT %" = 20 and Non-Deductible VAT %" = 75
        LibraryNonDeductibleVAT.CreateNonDeductibleNormalVATPostingSetup(VATPostingSetup);
        // [GIVEN] Purchase invoice with amount = 100. VAT Amount = 20. Non-Deductible VAT Amount = 15
        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
            LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        LibraryPurchase.CreatePurchaseLineWithUnitCost(
            PurchaseLine, PurchaseHeader, LibraryInventory.CreateItemWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"),
            LibraryRandom.RandDec(100, 2), LibraryRandom.RandInt(100));
        NonDeductibleVATAmount := PurchaseLine."Non-Deductible VAT Amount";
        VATAmount := PurchaseLine."Amount Including VAT" - PurchaseLine.Amount - MaxVATDifference;
        LibraryVariableStorage.Enqueue(NonDeductibleVATAmount);
        LibraryVariableStorage.Enqueue(VATAmount);

        // [GIVEN] Open purchase invoice page
        PurchaseInvoicePage.OpenEdit();
        PurchaseInvoicePage.Filter.SetFilter("No.", PurchaseHeader."No.");
        // [GIVEN] Open statistics of the invoice
        PurchaseInvoicePage.PurchaseStatistics.Invoke();

        // [WHEN] Set "VAT Amount" = 19.99
        // [THEN] "Non-Deductible VAT amount" remains 15 on statistics page
        // [THEN] "Deductible Amount" is 4.99
        // Called in PurchaseStatisticsModalPageHandler

        PurchaseLine.Find();
        // [THEN] "VAT Difference" is -0.01 in the purchase line
        PurchaseLine.TestField("VAT Difference", -MaxVATDifference);
        // [THEN] "Amount Including VAT" is 119.99 in the purchase line
        PurchaseLine.TestField("Amount Including VAT", PurchaseLine.Amount + VATAmount);
        // [THEN] "Non-Deductible VAT" is 15 in the purchase line
        PurchaseLine.TestField("Non-Deductible VAT Amount", NonDeductibleVATAmount);
        // [THEN] "Non-Deductible VAT Diff." is zero in the purchase line
        PurchaseLine.TestField("Non-Deductible VAT Diff.", 0);
        LibraryVariableStorage.AssertEmpty();
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseStatisticsChangeNonDedVATAmountModalPageHandler')]
    procedure VATAmountNotChangedWhenNonDedVATAmountChanged()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoicePage: TestPage "Purchase Invoice";
        MaxVATDifference: Decimal;
        VATAmount: Decimal;
        NonDeductibleVATAmount: Decimal;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 456471] VAT Amount is not changed in statistics when Stan changes the Non-Deductible VAT amount

        Initialize();
        MaxVATDifference := LibraryRandom.RandDecInDecimalRange(0.1, 1, 2);
        // [GIVEN] "Allow VAT Difference" is enabled in Purchases Setup
        // [GIVEN] "Max VAT Difference" is 0.01 in General Ledger Setup
        SetAllowVATDifference(MaxVATDifference);
        // [GIVEN] Normal VAT Posting Setup with "VAT %" = 20 and Non-Deductible VAT %" = 75
        LibraryNonDeductibleVAT.CreateNonDeductibleNormalVATPostingSetup(VATPostingSetup);
        // [GIVEN] Purchase invoice with amount = 100. VAT Amount = 20. Non-Deductible VAT Amount = 15
        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
            LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        LibraryPurchase.CreatePurchaseLineWithUnitCost(
            PurchaseLine, PurchaseHeader, LibraryInventory.CreateItemWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"),
            LibraryRandom.RandDec(100, 2), LibraryRandom.RandInt(100));
        NonDeductibleVATAmount := PurchaseLine."Non-Deductible VAT Amount" - MaxVATDifference;
        VATAmount := PurchaseLine."Amount Including VAT" - PurchaseLine.Amount;
        LibraryVariableStorage.Enqueue(NonDeductibleVATAmount);
        LibraryVariableStorage.Enqueue(VATAmount);

        // [GIVEN] Open purchase invoice page
        PurchaseInvoicePage.OpenEdit();
        PurchaseInvoicePage.Filter.SetFilter("No.", PurchaseHeader."No.");
        // [GIVEN] Open statistics of the invoice
        PurchaseInvoicePage.Statistics.Invoke();

        // [WHEN] Set "Non-Deductible VAT Amount" = 14.99
        // [THEN] "VAT amount" remains 20 on statistics page
        // [THEN] "Deductible Amount" is 4.99
        // Called in PurchaseStatisticsModalPageHandler

        PurchaseLine.Find();
        // [THEN] "VAT Difference" is zero in the purchase line
        PurchaseLine.TestField("VAT Difference", 0);
        // [THEN] "Amount Including VAT" is 120 in the purchase line
        PurchaseLine.TestField("Amount Including VAT", PurchaseLine.Amount + VATAmount);
        // [THEN] "Non-Deductible VAT" is 14.99 in the purchase line
        PurchaseLine.TestField("Non-Deductible VAT Amount", NonDeductibleVATAmount);
        // [THEN] "Non-Deductible VAT Diff." is -0.01 in the purchase line
        PurchaseLine.TestField("Non-Deductible VAT Diff.", -MaxVATDifference);
        LibraryVariableStorage.AssertEmpty();
    end;
#endif

    [Test]
    [HandlerFunctions('PurchaseStatisticsChangeNonDedVATAmountPageHandler')]
    procedure VATAmountNotChangedWhenNonDedVATAmntChanged()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoicePage: TestPage "Purchase Invoice";
        MaxVATDifference: Decimal;
        VATAmount: Decimal;
        NonDeductibleVATAmount: Decimal;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 456471] VAT Amount is not changed in statistics when Stan changes the Non-Deductible VAT amount

        Initialize();
        MaxVATDifference := LibraryRandom.RandDecInDecimalRange(0.1, 1, 2);
        // [GIVEN] "Allow VAT Difference" is enabled in Purchases Setup
        // [GIVEN] "Max VAT Difference" is 0.01 in General Ledger Setup
        SetAllowVATDifference(MaxVATDifference);
        // [GIVEN] Normal VAT Posting Setup with "VAT %" = 20 and Non-Deductible VAT %" = 75
        LibraryNonDeductibleVAT.CreateNonDeductibleNormalVATPostingSetup(VATPostingSetup);
        // [GIVEN] Purchase invoice with amount = 100. VAT Amount = 20. Non-Deductible VAT Amount = 15
        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
            LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        LibraryPurchase.CreatePurchaseLineWithUnitCost(
            PurchaseLine, PurchaseHeader, LibraryInventory.CreateItemWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"),
            LibraryRandom.RandDec(100, 2), LibraryRandom.RandInt(100));
        NonDeductibleVATAmount := PurchaseLine."Non-Deductible VAT Amount" - MaxVATDifference;
        VATAmount := PurchaseLine."Amount Including VAT" - PurchaseLine.Amount;
        LibraryVariableStorage.Enqueue(NonDeductibleVATAmount);
        LibraryVariableStorage.Enqueue(VATAmount);

        // [GIVEN] Open purchase invoice page
        PurchaseInvoicePage.OpenEdit();
        PurchaseInvoicePage.Filter.SetFilter("No.", PurchaseHeader."No.");
        // [GIVEN] Open statistics of the invoice
        PurchaseInvoicePage.PurchaseStatistics.Invoke();

        // [WHEN] Set "Non-Deductible VAT Amount" = 14.99
        // [THEN] "VAT amount" remains 20 on statistics page
        // [THEN] "Deductible Amount" is 4.99
        // Called in PurchaseStatisticsModalPageHandler

        PurchaseLine.Find();
        // [THEN] "VAT Difference" is zero in the purchase line
        PurchaseLine.TestField("VAT Difference", 0);
        // [THEN] "Amount Including VAT" is 120 in the purchase line
        PurchaseLine.TestField("Amount Including VAT", PurchaseLine.Amount + VATAmount);
        // [THEN] "Non-Deductible VAT" is 14.99 in the purchase line
        PurchaseLine.TestField("Non-Deductible VAT Amount", NonDeductibleVATAmount);
        // [THEN] "Non-Deductible VAT Diff." is -0.01 in the purchase line
        PurchaseLine.TestField("Non-Deductible VAT Diff.", -MaxVATDifference);
        LibraryVariableStorage.AssertEmpty();
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseStatisticsChangeVATAmtAndNonDedVATAmtModalPageHandler')]
    procedure SimultaneousChangeOfVATAmtAndNonDedVATAmt()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoicePage: TestPage "Purchase Invoice";
        MaxVATDifference: Decimal;
        VATAmount: Decimal;
        NonDeductibleVATAmount: Decimal;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 456471] Stan can simultaneously change the "VAT Amount" and "Non-Deductible VAT Amount" in statistics

        Initialize();
        MaxVATDifference := LibraryRandom.RandDecInDecimalRange(0.1, 1, 2);
        // [GIVEN] "Allow VAT Difference" is enabled in Purchases Setup
        // [GIVEN] "Max VAT Difference" is 0.01 in General Ledger Setup
        SetAllowVATDifference(MaxVATDifference);
        // [GIVEN] Normal VAT Posting Setup with "VAT %" = 20 and Non-Deductible VAT %" = 75
        LibraryNonDeductibleVAT.CreateNonDeductibleNormalVATPostingSetup(VATPostingSetup);
        // [GIVEN] Purchase invoice with amount = 100. VAT Amount = 20. Non-Deductible VAT Amount = 15
        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
            LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        LibraryPurchase.CreatePurchaseLineWithUnitCost(
            PurchaseLine, PurchaseHeader, LibraryInventory.CreateItemWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"),
            LibraryRandom.RandDec(100, 2), LibraryRandom.RandInt(100));
        NonDeductibleVATAmount := PurchaseLine."Non-Deductible VAT Amount" - MaxVATDifference;
        VATAmount := PurchaseLine."Amount Including VAT" - PurchaseLine.Amount - MaxVATDifference;
        LibraryVariableStorage.Enqueue(NonDeductibleVATAmount);
        LibraryVariableStorage.Enqueue(VATAmount);

        // [GIVEN] Open purchase invoice page
        PurchaseInvoicePage.OpenEdit();
        PurchaseInvoicePage.Filter.SetFilter("No.", PurchaseHeader."No.");
        // [GIVEN] Open statistics of the invoice
        PurchaseInvoicePage.Statistics.Invoke();

        // [WHEN] Set "VAT Amount" to 19.99 and "Non-Deductible VAT Amount" = 14.99
        // [THEN] "Deductible Amount" is 5
        // Called in PurchaseStatisticsModalPageHandler

        PurchaseLine.Find();
        // [THEN] "VAT Difference" is -0.01  in the purchase line
        PurchaseLine.TestField("VAT Difference", -MaxVATDifference);
        // [THEN] "Amount Including VAT" is 119.99 in the purchase line
        PurchaseLine.TestField("Amount Including VAT", PurchaseLine.Amount + VATAmount);
        // [THEN] "Non-Deductible VAT" is 14.99 in the purchase line
        PurchaseLine.TestField("Non-Deductible VAT Amount", NonDeductibleVATAmount);
        // [THEN] "Non-Deductible VAT Diff." is -0.01 in the purchase line
        PurchaseLine.TestField("Non-Deductible VAT Diff.", -MaxVATDifference);
        LibraryVariableStorage.AssertEmpty();
    end;
#endif

    [Test]
    [HandlerFunctions('PurchaseStatisticsChangeVATAmtAndNonDedVATAmtPageHandler')]
    procedure SimultaneousChangeOfVATAmtAndNonDedVATAmount()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoicePage: TestPage "Purchase Invoice";
        MaxVATDifference: Decimal;
        VATAmount: Decimal;
        NonDeductibleVATAmount: Decimal;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 456471] Stan can simultaneously change the "VAT Amount" and "Non-Deductible VAT Amount" in statistics

        Initialize();
        MaxVATDifference := LibraryRandom.RandDecInDecimalRange(0.1, 1, 2);
        // [GIVEN] "Allow VAT Difference" is enabled in Purchases Setup
        // [GIVEN] "Max VAT Difference" is 0.01 in General Ledger Setup
        SetAllowVATDifference(MaxVATDifference);
        // [GIVEN] Normal VAT Posting Setup with "VAT %" = 20 and Non-Deductible VAT %" = 75
        LibraryNonDeductibleVAT.CreateNonDeductibleNormalVATPostingSetup(VATPostingSetup);
        // [GIVEN] Purchase invoice with amount = 100. VAT Amount = 20. Non-Deductible VAT Amount = 15
        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
            LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        LibraryPurchase.CreatePurchaseLineWithUnitCost(
            PurchaseLine, PurchaseHeader, LibraryInventory.CreateItemWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"),
            LibraryRandom.RandDec(100, 2), LibraryRandom.RandInt(100));
        NonDeductibleVATAmount := PurchaseLine."Non-Deductible VAT Amount" - MaxVATDifference;
        VATAmount := PurchaseLine."Amount Including VAT" - PurchaseLine.Amount - MaxVATDifference;
        LibraryVariableStorage.Enqueue(NonDeductibleVATAmount);
        LibraryVariableStorage.Enqueue(VATAmount);

        // [GIVEN] Open purchase invoice page
        PurchaseInvoicePage.OpenEdit();
        PurchaseInvoicePage.Filter.SetFilter("No.", PurchaseHeader."No.");
        // [GIVEN] Open statistics of the invoice
        PurchaseInvoicePage.PurchaseStatistics.Invoke();

        // [WHEN] Set "VAT Amount" to 19.99 and "Non-Deductible VAT Amount" = 14.99
        // [THEN] "Deductible Amount" is 5
        // Called in PurchaseStatisticsModalPageHandler

        PurchaseLine.Find();
        // [THEN] "VAT Difference" is -0.01  in the purchase line
        PurchaseLine.TestField("VAT Difference", -MaxVATDifference);
        // [THEN] "Amount Including VAT" is 119.99 in the purchase line
        PurchaseLine.TestField("Amount Including VAT", PurchaseLine.Amount + VATAmount);
        // [THEN] "Non-Deductible VAT" is 14.99 in the purchase line
        PurchaseLine.TestField("Non-Deductible VAT Amount", NonDeductibleVATAmount);
        // [THEN] "Non-Deductible VAT Diff." is -0.01 in the purchase line
        PurchaseLine.TestField("Non-Deductible VAT Diff.", -MaxVATDifference);
        LibraryVariableStorage.AssertEmpty();
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseStatisticsChangeVATAmtAndNonDedVATAmtOrVerifyModalPageHandler')]
    procedure ReopenStatisticsAfterSimultaneousChangeOfVATAmtAndNonDedVATAmt()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoicePage: TestPage "Purchase Invoice";
        MaxVATDifference: Decimal;
        VATAmount: Decimal;
        NonDeductibleVATAmount: Decimal;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 456471] The values of VAT in reopened statistics are correct after simultaneous change of "VAT Amount" and "Non-Deductible VAT Amount"

        Initialize();
        MaxVATDifference := LibraryRandom.RandDecInDecimalRange(0.1, 1, 2);
        // [GIVEN] "Allow VAT Difference" is enabled in Purchases Setup
        // [GIVEN] "Max VAT Difference" is 0.01 in General Ledger Setup
        SetAllowVATDifference(MaxVATDifference);
        // [GIVEN] Normal VAT Posting Setup with "VAT %" = 20 and Non-Deductible VAT %" = 75
        LibraryNonDeductibleVAT.CreateNonDeductibleNormalVATPostingSetup(VATPostingSetup);
        // [GIVEN] Purchase invoice with amount = 100. VAT Amount = 20. Non-Deductible VAT Amount = 15
        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
            LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        LibraryPurchase.CreatePurchaseLineWithUnitCost(
            PurchaseLine, PurchaseHeader, LibraryInventory.CreateItemWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"),
            LibraryRandom.RandDec(100, 2), LibraryRandom.RandInt(100));
        NonDeductibleVATAmount := PurchaseLine."Non-Deductible VAT Amount" - MaxVATDifference;
        VATAmount := PurchaseLine."Amount Including VAT" - PurchaseLine.Amount - MaxVATDifference;
        // Variables to set values in statistics
        LibraryVariableStorage.Enqueue(false); // set values
        LibraryVariableStorage.Enqueue(NonDeductibleVATAmount);
        LibraryVariableStorage.Enqueue(VATAmount);

        // Variables to set values in statistics
        LibraryVariableStorage.Enqueue(true); // verify values
        LibraryVariableStorage.Enqueue(NonDeductibleVATAmount);
        LibraryVariableStorage.Enqueue(VATAmount);

        // [GIVEN] Open purchase invoice page
        PurchaseInvoicePage.OpenEdit();
        PurchaseInvoicePage.Filter.SetFilter("No.", PurchaseHeader."No.");
        // [GIVEN] Open statistics of the invoice
        PurchaseInvoicePage.Statistics.Invoke();

        // Called in PurchaseStatisticsModalPageHandler
        // [GIVEN] Set "VAT Amount" to 19.99 and "Non-Deductible VAT Amount" = 14.99
        // [GIVEN] Close the statistics page
        // [WHEN] Reopen the statistics page again
        PurchaseInvoicePage.Statistics.Invoke();
        // [THEN] "VAT Amount" is 19.99 in statistics page
        // [THEN] "Non-Deductible VAT Amount" is 14.99 in statistics page
        // [THEN] "Deductible Amount" is 5

        PurchaseLine.Find();
        // [THEN] "VAT Difference" is -0.01  in the purchase line
        PurchaseLine.TestField("VAT Difference", -MaxVATDifference);
        // [THEN] "Amount Including VAT" is 119.99 in the purchase line
        PurchaseLine.TestField("Amount Including VAT", PurchaseLine.Amount + VATAmount);
        // [THEN] "Non-Deductible VAT" is 14.99 in the purchase line
        PurchaseLine.TestField("Non-Deductible VAT Amount", NonDeductibleVATAmount);
        // [THEN] "Non-Deductible VAT Diff." is -0.01 in the purchase line
        PurchaseLine.TestField("Non-Deductible VAT Diff.", -MaxVATDifference);
        LibraryVariableStorage.AssertEmpty();
    end;
#endif

    [Test]
    [HandlerFunctions('PurchaseStatisticsChangeVATAmtAndNonDedVATAmtOrVerifyPageHandler')]
    procedure ReopenPurchStatisticsAfterSimultaneousChangeOfVATAmtAndNonDedVATAmt()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoicePage: TestPage "Purchase Invoice";
        MaxVATDifference: Decimal;
        VATAmount: Decimal;
        NonDeductibleVATAmount: Decimal;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 456471] The values of VAT in reopened statistics are correct after simultaneous change of "VAT Amount" and "Non-Deductible VAT Amount"

        Initialize();
        MaxVATDifference := LibraryRandom.RandDecInDecimalRange(0.1, 1, 2);
        // [GIVEN] "Allow VAT Difference" is enabled in Purchases Setup
        // [GIVEN] "Max VAT Difference" is 0.01 in General Ledger Setup
        SetAllowVATDifference(MaxVATDifference);
        // [GIVEN] Normal VAT Posting Setup with "VAT %" = 20 and Non-Deductible VAT %" = 75
        LibraryNonDeductibleVAT.CreateNonDeductibleNormalVATPostingSetup(VATPostingSetup);
        // [GIVEN] Purchase invoice with amount = 100. VAT Amount = 20. Non-Deductible VAT Amount = 15
        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
            LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        LibraryPurchase.CreatePurchaseLineWithUnitCost(
            PurchaseLine, PurchaseHeader, LibraryInventory.CreateItemWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"),
            LibraryRandom.RandDec(100, 2), LibraryRandom.RandInt(100));
        NonDeductibleVATAmount := PurchaseLine."Non-Deductible VAT Amount" - MaxVATDifference;
        VATAmount := PurchaseLine."Amount Including VAT" - PurchaseLine.Amount - MaxVATDifference;
        // Variables to set values in statistics
        LibraryVariableStorage.Enqueue(false); // set values
        LibraryVariableStorage.Enqueue(NonDeductibleVATAmount);
        LibraryVariableStorage.Enqueue(VATAmount);

        // Variables to set values in statistics
        LibraryVariableStorage.Enqueue(true); // verify values
        LibraryVariableStorage.Enqueue(NonDeductibleVATAmount);
        LibraryVariableStorage.Enqueue(VATAmount);

        // [GIVEN] Open purchase invoice page
        PurchaseInvoicePage.OpenEdit();
        PurchaseInvoicePage.Filter.SetFilter("No.", PurchaseHeader."No.");
        // [GIVEN] Open statistics of the invoice
        PurchaseInvoicePage.PurchaseStatistics.Invoke();

        // Called in PurchaseStatisticsModalPageHandler
        // [GIVEN] Set "VAT Amount" to 19.99 and "Non-Deductible VAT Amount" = 14.99
        // [GIVEN] Close the statistics page
        // [WHEN] Reopen the statistics page again
        PurchaseInvoicePage.PurchaseStatistics.Invoke();
        // [THEN] "VAT Amount" is 19.99 in statistics page
        // [THEN] "Non-Deductible VAT Amount" is 14.99 in statistics page
        // [THEN] "Deductible Amount" is 5

        PurchaseLine.Find();
        // [THEN] "VAT Difference" is -0.01  in the purchase line
        PurchaseLine.TestField("VAT Difference", -MaxVATDifference);
        // [THEN] "Amount Including VAT" is 119.99 in the purchase line
        PurchaseLine.TestField("Amount Including VAT", PurchaseLine.Amount + VATAmount);
        // [THEN] "Non-Deductible VAT" is 14.99 in the purchase line
        PurchaseLine.TestField("Non-Deductible VAT Amount", NonDeductibleVATAmount);
        // [THEN] "Non-Deductible VAT Diff." is -0.01 in the purchase line
        PurchaseLine.TestField("Non-Deductible VAT Diff.", -MaxVATDifference);
        LibraryVariableStorage.AssertEmpty();
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseStatisticsChangeVATAmtAndNonDedVATAmtModalPageHandler')]
    procedure PostingOfPurchInvWithChangedVATAmtAndNonDedVATAmt()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATEntry: Record "VAT Entry";
        GeneralPostingSetup: Record "General Posting Setup";
        PurchaseInvoicePage: TestPage "Purchase Invoice";
        MaxVATDifference: Decimal;
        VATAmount: Decimal;
        NonDeductibleVATAmount: Decimal;
        DocNo: Code[20];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 456471] The posting results are correct after simultaneous change of "VAT Amount" and "Non-Deductible VAT Amount"

        Initialize();
        MaxVATDifference := LibraryRandom.RandDecInDecimalRange(0.1, 1, 2);
        // [GIVEN] "Allow VAT Difference" is enabled in Purchases Setup
        // [GIVEN] "Max VAT Difference" is 0.01 in General Ledger Setup
        SetAllowVATDifference(MaxVATDifference);
        // [GIVEN] Normal VAT Posting Setup with "VAT %" = 20 and Non-Deductible VAT %" = 75
        LibraryNonDeductibleVAT.CreateNonDeductibleNormalVATPostingSetup(VATPostingSetup);
        // [GIVEN] Purchase invoice with amount = 100. VAT Amount = 20. Non-Deductible VAT Amount = 15
        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
            LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        LibraryPurchase.CreatePurchaseLineWithUnitCost(
            PurchaseLine, PurchaseHeader, LibraryInventory.CreateItemWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"),
            LibraryRandom.RandDec(100, 2), LibraryRandom.RandInt(100));
        NonDeductibleVATAmount := PurchaseLine."Non-Deductible VAT Amount" - MaxVATDifference;
        VATAmount := PurchaseLine."Amount Including VAT" - PurchaseLine.Amount - MaxVATDifference;
        LibraryVariableStorage.Enqueue(NonDeductibleVATAmount);
        LibraryVariableStorage.Enqueue(VATAmount);

        // [GIVEN] Open purchase invoice page
        PurchaseInvoicePage.OpenEdit();
        PurchaseInvoicePage.Filter.SetFilter("No.", PurchaseHeader."No.");
        // [GIVEN] Open statistics of the invoice
        PurchaseInvoicePage.Statistics.Invoke();
        PurchaseLine.Find();
        // Called in PurchaseStatisticsModalPageHandler
        // [GIVEN] Set "VAT Amount" to 19.99 and "Non-Deductible VAT Amount" = 14.99

        // [WHEN] Post purchase invoice
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Posted VAT Entry has "Non-Deductible VAT Amount" = 14.99
        // [THEN] Posted VAT Entry has "Non-Deductible VAT Diff." = 0.01
        FindVATEntry(VATEntry, DocNo);
        VATEntry.TestField("Non-Deductible VAT Amount", PurchaseLine."Non-Deductible VAT Amount");
        VATEntry.TestField("Non-Deductible VAT Diff.", PurchaseLine."Non-Deductible VAT Diff.");
        // [THEN] G/L Entries with purchases account have total amount of 114.99
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        VerifyGLEntry(DocNo, GeneralPostingSetup."Purch. Account", 2, PurchaseLine.Amount + PurchaseLine."Non-Deductible VAT Amount");

        LibraryVariableStorage.AssertEmpty();
    end;
#endif

    [Test]
    [HandlerFunctions('PurchaseStatisticsChangeVATAmtAndNonDedVATAmtPageHandler')]
    procedure PostingOfPurchInvWithChangedVATAmtAndNonDedVATAmount()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATEntry: Record "VAT Entry";
        GeneralPostingSetup: Record "General Posting Setup";
        PurchaseInvoicePage: TestPage "Purchase Invoice";
        MaxVATDifference: Decimal;
        VATAmount: Decimal;
        NonDeductibleVATAmount: Decimal;
        DocNo: Code[20];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 456471] The posting results are correct after simultaneous change of "VAT Amount" and "Non-Deductible VAT Amount"

        Initialize();
        MaxVATDifference := LibraryRandom.RandDecInDecimalRange(0.1, 1, 2);
        // [GIVEN] "Allow VAT Difference" is enabled in Purchases Setup
        // [GIVEN] "Max VAT Difference" is 0.01 in General Ledger Setup
        SetAllowVATDifference(MaxVATDifference);
        // [GIVEN] Normal VAT Posting Setup with "VAT %" = 20 and Non-Deductible VAT %" = 75
        LibraryNonDeductibleVAT.CreateNonDeductibleNormalVATPostingSetup(VATPostingSetup);
        // [GIVEN] Purchase invoice with amount = 100. VAT Amount = 20. Non-Deductible VAT Amount = 15
        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
            LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        LibraryPurchase.CreatePurchaseLineWithUnitCost(
            PurchaseLine, PurchaseHeader, LibraryInventory.CreateItemWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"),
            LibraryRandom.RandDec(100, 2), LibraryRandom.RandInt(100));
        NonDeductibleVATAmount := PurchaseLine."Non-Deductible VAT Amount" - MaxVATDifference;
        VATAmount := PurchaseLine."Amount Including VAT" - PurchaseLine.Amount - MaxVATDifference;
        LibraryVariableStorage.Enqueue(NonDeductibleVATAmount);
        LibraryVariableStorage.Enqueue(VATAmount);

        // [GIVEN] Open purchase invoice page
        PurchaseInvoicePage.OpenEdit();
        PurchaseInvoicePage.Filter.SetFilter("No.", PurchaseHeader."No.");
        // [GIVEN] Open statistics of the invoice
        PurchaseInvoicePage.PurchaseStatistics.Invoke();
        PurchaseLine.Find();
        // Called in PurchaseStatisticsModalPageHandler
        // [GIVEN] Set "VAT Amount" to 19.99 and "Non-Deductible VAT Amount" = 14.99

        // [WHEN] Post purchase invoice
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Posted VAT Entry has "Non-Deductible VAT Amount" = 14.99
        // [THEN] Posted VAT Entry has "Non-Deductible VAT Diff." = 0.01
        FindVATEntry(VATEntry, DocNo);
        VATEntry.TestField("Non-Deductible VAT Amount", PurchaseLine."Non-Deductible VAT Amount");
        VATEntry.TestField("Non-Deductible VAT Diff.", PurchaseLine."Non-Deductible VAT Diff.");
        // [THEN] G/L Entries with purchases account have total amount of 114.99
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        VerifyGLEntry(DocNo, GeneralPostingSetup."Purch. Account", 2, PurchaseLine.Amount + PurchaseLine."Non-Deductible VAT Amount");

        LibraryVariableStorage.AssertEmpty();
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsDrillDownInvLinesModalPageHandler,VATAmountLinesCheckOrVerifyNonDedVATAmtModalPageHandler')]
    procedure NonDedVATAmtInPurchOrderMultipleLines()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOrderPage: TestPage "Purchase Order";
        LineCount: Integer;
        MaxVATDifference: Decimal;
        NonDedVATAmount: Decimal;
        VATAmount: Decimal;
        i: Integer;
    begin
        // [FEATURE] The "VAT Amount" and "Non-Deductible VAT amount" are correct for the purchase order with "Qty To Invoice" changed for partial posting

        Initialize();
        LineCount := LibraryRandom.RandIntInRange(3, 5);
        MaxVATDifference := LineCount * LibraryRandom.RandDecInDecimalRange(0.1, 1, 2);
        // [GIVEN] "Allow VAT Difference" is enabled in Purchases Setup
        // [GIVEN] "Max VAT Difference" is 0.01 in General Ledger Setup
        SetAllowVATDifference(MaxVATDifference);
        // [GIVEN] Normal VAT Posting Setup with "VAT %" = 20 and Non-Deductible VAT %" = 75
        LibraryNonDeductibleVAT.CreateNonDeductibleNormalVATPostingSetup(VATPostingSetup);
        // [GIVEN] Purchase order with Quantity = 2, Amount = 100. VAT Amount = 20. Non-Deductible VAT Amount = 15
        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader, PurchaseHeader."Document Type"::Order,
            LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        for i := 1 to LineCount do begin
            LibraryPurchase.CreatePurchaseLineWithUnitCost(
                PurchaseLine, PurchaseHeader, LibraryInventory.CreateItemWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"),
                LibraryRandom.RandDec(100, 2), LibraryRandom.RandInt(100));
            NonDedVATAmount += (PurchaseLine."Amount Including VAT" - PurchaseLine.Amount) * VATPostingSetup."Non-Deductible VAT %" / 100;
            VATAmount += PurchaseLine."Amount Including VAT" - PurchaseLine.Amount;
        end;
        NonDedVATAmount := Round(NonDedVATAmount) - MaxVATDifference;
        VATAmount -= MaxVATDifference;

        // Variables to set value in statistics
        LibraryVariableStorage.Enqueue(false); // set value
        LibraryVariableStorage.Enqueue(NonDedVATAmount);
        LibraryVariableStorage.Enqueue(VATAmount);

        // [GIVEN] Open purchase order page
        PurchaseOrderPage.OpenEdit();
        PurchaseOrderPage.Filter.SetFilter("No.", PurchaseHeader."No.");
        // [GIVEN] Open statistics of the invoice
        PurchaseOrderPage.Statistics.Invoke();
        // [GIVEN] Change "Non-Deductible VAT Amount" to 7.4 in statistics
        // [GIVEN] Change "VAT Amount" to 9.9 in statistics
        // Sets in VATAmountLinesCheckOrVerifyNonDedVATAmtModalPageHandler

        // Variables to set value in statistics
        LibraryVariableStorage.Enqueue(true); // verify value
        LibraryVariableStorage.Enqueue(NonDedVATAmount);
        LibraryVariableStorage.Enqueue(VATAmount);
        // [WHEN] Open purchase order statistics
        PurchaseOrderPage.Statistics.Invoke();
        // [THEN] "Non-Deductible VAT Amount" is 7.4 in statistics
        // [THEN] "VAT Amount" is 9.9 in statistics
        // Verifies in VATAmountLinesCheckOrVerifyNonDedVATAmtModalPageHandler

        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.CalcSums("VAT Difference", "Non-Deductible VAT Diff.");
        // [THEN] "VAT Difference" is -0.01  in the purchase line
        PurchaseLine.TestField("VAT Difference", -MaxVATDifference);
        // [THEN] "Non-Deductible VAT Diff." is -0.01 in the purchase line
        PurchaseLine.TestField("Non-Deductible VAT Diff.", -MaxVATDifference);

        LibraryVariableStorage.AssertEmpty();
    end;
#endif

    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsDrillDownInvLinesPageHandler,VATAmountLinesCheckOrVerifyNonDedVATAmtModalPageHandler')]
    procedure NonDedVATAmtInPurchaseOrderMultipleLines()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOrderPage: TestPage "Purchase Order";
        LineCount: Integer;
        MaxVATDifference: Decimal;
        NonDedVATAmount: Decimal;
        VATAmount: Decimal;
        i: Integer;
    begin
        // [FEATURE] The "VAT Amount" and "Non-Deductible VAT amount" are correct for the purchase order with "Qty To Invoice" changed for partial posting

        Initialize();
        LineCount := LibraryRandom.RandIntInRange(3, 5);
        MaxVATDifference := LineCount * LibraryRandom.RandDecInDecimalRange(0.1, 1, 2);
        // [GIVEN] "Allow VAT Difference" is enabled in Purchases Setup
        // [GIVEN] "Max VAT Difference" is 0.01 in General Ledger Setup
        SetAllowVATDifference(MaxVATDifference);
        // [GIVEN] Normal VAT Posting Setup with "VAT %" = 20 and Non-Deductible VAT %" = 75
        LibraryNonDeductibleVAT.CreateNonDeductibleNormalVATPostingSetup(VATPostingSetup);
        // [GIVEN] Purchase order with Quantity = 2, Amount = 100. VAT Amount = 20. Non-Deductible VAT Amount = 15
        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader, PurchaseHeader."Document Type"::Order,
            LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        for i := 1 to LineCount do begin
            LibraryPurchase.CreatePurchaseLineWithUnitCost(
                PurchaseLine, PurchaseHeader, LibraryInventory.CreateItemWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"),
                LibraryRandom.RandDec(100, 2), LibraryRandom.RandInt(100));
            NonDedVATAmount += (PurchaseLine."Amount Including VAT" - PurchaseLine.Amount) * VATPostingSetup."Non-Deductible VAT %" / 100;
            VATAmount += PurchaseLine."Amount Including VAT" - PurchaseLine.Amount;
        end;
        NonDedVATAmount := Round(NonDedVATAmount) - MaxVATDifference;
        VATAmount -= MaxVATDifference;

        // Variables to set value in statistics
        LibraryVariableStorage.Enqueue(false); // set value
        LibraryVariableStorage.Enqueue(NonDedVATAmount);
        LibraryVariableStorage.Enqueue(VATAmount);

        // [GIVEN] Open purchase order page
        PurchaseOrderPage.OpenEdit();
        PurchaseOrderPage.Filter.SetFilter("No.", PurchaseHeader."No.");
        // [GIVEN] Open statistics of the invoice
        PurchaseOrderPage.PurchaseOrderStatistics.Invoke();
        // [GIVEN] Change "Non-Deductible VAT Amount" to 7.4 in statistics
        // [GIVEN] Change "VAT Amount" to 9.9 in statistics
        // Sets in VATAmountLinesCheckOrVerifyNonDedVATAmtModalPageHandler

        // Variables to set value in statistics
        LibraryVariableStorage.Enqueue(true); // verify value
        LibraryVariableStorage.Enqueue(NonDedVATAmount);
        LibraryVariableStorage.Enqueue(VATAmount);
        // [WHEN] Open purchase order statistics
        PurchaseOrderPage.PurchaseOrderStatistics.Invoke();
        // [THEN] "Non-Deductible VAT Amount" is 7.4 in statistics
        // [THEN] "VAT Amount" is 9.9 in statistics
        // Verifies in VATAmountLinesCheckOrVerifyNonDedVATAmtModalPageHandler

        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.CalcSums("VAT Difference", "Non-Deductible VAT Diff.");
        // [THEN] "VAT Difference" is -0.01  in the purchase line
        PurchaseLine.TestField("VAT Difference", -MaxVATDifference);
        // [THEN] "Non-Deductible VAT Diff." is -0.01 in the purchase line
        PurchaseLine.TestField("Non-Deductible VAT Diff.", -MaxVATDifference);

        LibraryVariableStorage.AssertEmpty();
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsDrillDownInvLinesModalPageHandler,VATAmountLinesCheckOrVerifyNonDedVATAmtModalPageHandler')]
    procedure NonDedVATAmtInPurchOrderToBePartiallyPosted()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        OriginalPurchaseLine: Record "Purchase Line";
        PurchaseOrderPage: TestPage "Purchase Order";
        Quantity: Integer;
        MaxVATDifference: Decimal;
        NonDedVATAmount: Decimal;
        VATAmount: Decimal;
    begin
        // [SCENARIO] The "VAT Amount" and "Non-Deductible VAT amount" are correct for the purchase order with "Qty To Invoice" changed for partial posting

        Initialize();
        Quantity := 2;
        MaxVATDifference := LibraryRandom.RandDecInDecimalRange(0.1, 1, 2);
        // [GIVEN] "Allow VAT Difference" is enabled in Purchases Setup
        // [GIVEN] "Max VAT Difference" is 0.01 in General Ledger Setup
        SetAllowVATDifference(MaxVATDifference);
        // [GIVEN] Normal VAT Posting Setup with "VAT %" = 20 and Non-Deductible VAT %" = 75
        LibraryNonDeductibleVAT.CreateNonDeductibleNormalVATPostingSetup(VATPostingSetup);
        // [GIVEN] Purchase order with Quantity = 2, Amount = 100. VAT Amount = 20. Non-Deductible VAT Amount = 15
        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader, PurchaseHeader."Document Type"::Order,
            LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        LibraryPurchase.CreatePurchaseLineWithUnitCost(
            PurchaseLine, PurchaseHeader, LibraryInventory.CreateItemWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"),
            LibraryRandom.RandDec(100, 2), Quantity);
        // [GIVEN] Set "Qty to Invoice" = 1. For invoicing the numbers will be: VAT Amount = 10. Non-Deductible VAT Amount = 7.5
        OriginalPurchaseLine := PurchaseLine;
        PurchaseLine.Validate("Qty. to Invoice", Quantity / 2);
        PurchaseLine.Modify(true);
        NonDedVATAmount := (PurchaseLine."Amount Including VAT" - PurchaseLine.Amount) * VATPostingSetup."Non-Deductible VAT %" / 100;
        NonDedVATAmount := Round(NonDedVATAmount * PurchaseLine."Qty. to Invoice" / PurchaseLine.Quantity) - MaxVATDifference;
        VATAmount := Round((PurchaseLine."Amount Including VAT" - PurchaseLine.Amount) * PurchaseLine."Qty. to Invoice" / PurchaseLine.Quantity) - MaxVATDifference;

        // Variables to set value in statistics
        LibraryVariableStorage.Enqueue(false); // set value
        LibraryVariableStorage.Enqueue(NonDedVATAmount);
        LibraryVariableStorage.Enqueue(VATAmount);

        // [GIVEN] Open purchase order page
        PurchaseOrderPage.OpenEdit();
        PurchaseOrderPage.Filter.SetFilter("No.", PurchaseHeader."No.");
        // [GIVEN] Open statistics of the invoice
        PurchaseOrderPage.Statistics.Invoke();
        // [GIVEN] Change "Non-Deductible VAT Amount" to 7.4 in statistics
        // [GIVEN] Change "VAT Amount" to 9.9 in statistics
        // Sets in VATAmountLinesCheckOrVerifyNonDedVATAmtModalPageHandler

        // Variables to set value in statistics
        LibraryVariableStorage.Enqueue(true); // verify value
        LibraryVariableStorage.Enqueue(NonDedVATAmount);
        LibraryVariableStorage.Enqueue(VATAmount);
        // [WHEN] Open purchase order statistics
        PurchaseOrderPage.Statistics.Invoke();
        // [THEN] "Non-Deductible VAT Amount" is 7.4 in statistics
        // [THEN] "VAT Amount" is 9.9 in statistics
        // Verifies in VATAmountLinesCheckOrVerifyNonDedVATAmtModalPageHandler

        PurchaseLine.Find();
        // [THEN] "VAT Difference" is -0.01  in the purchase line
        PurchaseLine.TestField("VAT Difference", -MaxVATDifference);
        // [THEN] "Amount Including VAT" is 119.99 in the purchase line
        PurchaseLine.TestField("Amount Including VAT", OriginalPurchaseLine."Amount Including VAT" - MaxVATDifference);
        // [THEN] "Non-Deductible VAT" is 14.99 in the purchase line
        PurchaseLine.TestField("Non-Deductible VAT Amount", OriginalPurchaseLine."Non-Deductible VAT Amount" - MaxVATDifference);
        // [THEN] "Non-Deductible VAT Diff." is -0.01 in the purchase line
        PurchaseLine.TestField("Non-Deductible VAT Diff.", -MaxVATDifference);
        LibraryVariableStorage.AssertEmpty();
    end;
#endif

    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsDrillDownInvLinesPageHandler,VATAmountLinesCheckOrVerifyNonDedVATAmtModalPageHandler')]
    procedure NonDedVATAmtInPurchaseOrderToBePartiallyPosted()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        OriginalPurchaseLine: Record "Purchase Line";
        PurchaseOrderPage: TestPage "Purchase Order";
        Quantity: Integer;
        MaxVATDifference: Decimal;
        NonDedVATAmount: Decimal;
        VATAmount: Decimal;
    begin
        // [SCENARIO] The "VAT Amount" and "Non-Deductible VAT amount" are correct for the purchase order with "Qty To Invoice" changed for partial posting

        Initialize();
        Quantity := 2;
        MaxVATDifference := LibraryRandom.RandDecInDecimalRange(0.1, 1, 2);
        // [GIVEN] "Allow VAT Difference" is enabled in Purchases Setup
        // [GIVEN] "Max VAT Difference" is 0.01 in General Ledger Setup
        SetAllowVATDifference(MaxVATDifference);
        // [GIVEN] Normal VAT Posting Setup with "VAT %" = 20 and Non-Deductible VAT %" = 75
        LibraryNonDeductibleVAT.CreateNonDeductibleNormalVATPostingSetup(VATPostingSetup);
        // [GIVEN] Purchase order with Quantity = 2, Amount = 100. VAT Amount = 20. Non-Deductible VAT Amount = 15
        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader, PurchaseHeader."Document Type"::Order,
            LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        LibraryPurchase.CreatePurchaseLineWithUnitCost(
            PurchaseLine, PurchaseHeader, LibraryInventory.CreateItemWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"),
            LibraryRandom.RandDec(100, 2), Quantity);
        // [GIVEN] Set "Qty to Invoice" = 1. For invoicing the numbers will be: VAT Amount = 10. Non-Deductible VAT Amount = 7.5
        OriginalPurchaseLine := PurchaseLine;
        PurchaseLine.Validate("Qty. to Invoice", Quantity / 2);
        PurchaseLine.Modify(true);
        NonDedVATAmount := (PurchaseLine."Amount Including VAT" - PurchaseLine.Amount) * VATPostingSetup."Non-Deductible VAT %" / 100;
        NonDedVATAmount := Round(NonDedVATAmount * PurchaseLine."Qty. to Invoice" / PurchaseLine.Quantity) - MaxVATDifference;
        VATAmount := Round((PurchaseLine."Amount Including VAT" - PurchaseLine.Amount) * PurchaseLine."Qty. to Invoice" / PurchaseLine.Quantity) - MaxVATDifference;

        // Variables to set value in statistics
        LibraryVariableStorage.Enqueue(false); // set value
        LibraryVariableStorage.Enqueue(NonDedVATAmount);
        LibraryVariableStorage.Enqueue(VATAmount);

        // [GIVEN] Open purchase order page
        PurchaseOrderPage.OpenEdit();
        PurchaseOrderPage.Filter.SetFilter("No.", PurchaseHeader."No.");
        // [GIVEN] Open statistics of the invoice
        PurchaseOrderPage.PurchaseOrderStatistics.Invoke();
        // [GIVEN] Change "Non-Deductible VAT Amount" to 7.4 in statistics
        // [GIVEN] Change "VAT Amount" to 9.9 in statistics
        // Sets in VATAmountLinesCheckOrVerifyNonDedVATAmtModalPageHandler

        // Variables to set value in statistics
        LibraryVariableStorage.Enqueue(true); // verify value
        LibraryVariableStorage.Enqueue(NonDedVATAmount);
        LibraryVariableStorage.Enqueue(VATAmount);
        // [WHEN] Open purchase order statistics
        PurchaseOrderPage.PurchaseOrderStatistics.Invoke();
        // [THEN] "Non-Deductible VAT Amount" is 7.4 in statistics
        // [THEN] "VAT Amount" is 9.9 in statistics
        // Verifies in VATAmountLinesCheckOrVerifyNonDedVATAmtModalPageHandler

        PurchaseLine.Find();
        // [THEN] "VAT Difference" is -0.01  in the purchase line
        PurchaseLine.TestField("VAT Difference", -MaxVATDifference);
        // [THEN] "Amount Including VAT" is 119.99 in the purchase line
        PurchaseLine.TestField("Amount Including VAT", OriginalPurchaseLine."Amount Including VAT" - MaxVATDifference);
        // [THEN] "Non-Deductible VAT" is 14.99 in the purchase line
        PurchaseLine.TestField("Non-Deductible VAT Amount", OriginalPurchaseLine."Non-Deductible VAT Amount" - MaxVATDifference);
        // [THEN] "Non-Deductible VAT Diff." is -0.01 in the purchase line
        PurchaseLine.TestField("Non-Deductible VAT Diff.", -MaxVATDifference);
        LibraryVariableStorage.AssertEmpty();
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseStatisticsChangeNonDedVATAmountModalPageHandler')]
    procedure CannotSetNonDedVATAmtMoreThanVATAmt()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoicePage: TestPage "Purchase Invoice";
        MaxVATDifference: Decimal;
        VATAmount: Decimal;
        NonDeductibleVATAmount: Decimal;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 456471] Stan cannot set "Non-Deductible VAT Amount" more than "VAT Amount"

        Initialize();
        MaxVATDifference := LibraryRandom.RandDecInDecimalRange(0.1, 1, 2);
        // [GIVEN] "Allow VAT Difference" is enabled in Purchases Setup
        // [GIVEN] "Max VAT Difference" is 0.01 in General Ledger Setup
        SetAllowVATDifference(MaxVATDifference);
        // [GIVEN] Normal VAT Posting Setup with "VAT %" = 20 and Non-Deductible VAT %" = 100
        LibraryNonDeductibleVAT.CreateNonDeductibleNormalVATPostingSetup(VATPostingSetup);
        VATPostingSetup.Validate("Non-Deductible VAT %", 100);
        VATPostingSetup.Modify(true);
        // [GIVEN] Purchase invoice with amount = 100. VAT Amount = 20. Non-Deductible VAT Amount = 20
        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
            LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        LibraryPurchase.CreatePurchaseLineWithUnitCost(
            PurchaseLine, PurchaseHeader, LibraryInventory.CreateItemWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"),
            LibraryRandom.RandDec(100, 2), LibraryRandom.RandInt(100));
        NonDeductibleVATAmount := PurchaseLine."Non-Deductible VAT Amount" + MaxVATDifference;
        VATAmount := PurchaseLine."Amount Including VAT" - PurchaseLine.Amount;
        LibraryVariableStorage.Enqueue(NonDeductibleVATAmount);
        LibraryVariableStorage.Enqueue(VATAmount);

        // [GIVEN] Open purchase invoice page
        PurchaseInvoicePage.OpenEdit();
        PurchaseInvoicePage.Filter.SetFilter("No.", PurchaseHeader."No.");
        // [WHEN] Set "VAT Amount" = 20.01
        asserterror PurchaseInvoicePage.Statistics.Invoke();

        // [THEN] "Non-Deductible VAT amount" remains 15 on statistics page
        Assert.ExpectedError('Deductible VAT Amount cannot be negative');
        LibraryVariableStorage.AssertEmpty();
    end;
#endif

    [Test]
    [HandlerFunctions('PurchaseStatisticsChangeNonDedVATAmountPageHandler')]
    procedure CannotSetNonDedVATAmntMoreThanVATAmnt()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoicePage: TestPage "Purchase Invoice";
        MaxVATDifference: Decimal;
        VATAmount: Decimal;
        NonDeductibleVATAmount: Decimal;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 456471] Stan cannot set "Non-Deductible VAT Amount" more than "VAT Amount"

        Initialize();
        MaxVATDifference := LibraryRandom.RandDecInDecimalRange(0.1, 1, 2);
        // [GIVEN] "Allow VAT Difference" is enabled in Purchases Setup
        // [GIVEN] "Max VAT Difference" is 0.01 in General Ledger Setup
        SetAllowVATDifference(MaxVATDifference);
        // [GIVEN] Normal VAT Posting Setup with "VAT %" = 20 and Non-Deductible VAT %" = 100
        LibraryNonDeductibleVAT.CreateNonDeductibleNormalVATPostingSetup(VATPostingSetup);
        VATPostingSetup.Validate("Non-Deductible VAT %", 100);
        VATPostingSetup.Modify(true);
        // [GIVEN] Purchase invoice with amount = 100. VAT Amount = 20. Non-Deductible VAT Amount = 20
        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
            LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        LibraryPurchase.CreatePurchaseLineWithUnitCost(
            PurchaseLine, PurchaseHeader, LibraryInventory.CreateItemWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"),
            LibraryRandom.RandDec(100, 2), LibraryRandom.RandInt(100));
        NonDeductibleVATAmount := PurchaseLine."Non-Deductible VAT Amount" + MaxVATDifference;
        VATAmount := PurchaseLine."Amount Including VAT" - PurchaseLine.Amount;
        LibraryVariableStorage.Enqueue(NonDeductibleVATAmount);
        LibraryVariableStorage.Enqueue(VATAmount);

        // [GIVEN] Open purchase invoice page
        PurchaseInvoicePage.OpenEdit();
        PurchaseInvoicePage.Filter.SetFilter("No.", PurchaseHeader."No.");
        // [WHEN] Set "VAT Amount" = 20.01
        asserterror PurchaseInvoicePage.PurchaseStatistics.Invoke();

        // [THEN] "Non-Deductible VAT amount" remains 15 on statistics page
        Assert.ExpectedError('Deductible VAT Amount cannot be negative');
        LibraryVariableStorage.AssertEmpty();
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseStatisticsChangeVATAmountModalPageHandler')]
    procedure ChangeNonDedVATAmountOnVATAmountChangeIfNDVATPctIs100()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoicePage: TestPage "Purchase Invoice";
        MaxVATDifference: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 456471] Non-Deductible VAT Amount is changed in statistics when Stan changes the VAT amount in case if "Non-Deductible VAT %" is 100

        Initialize();
        MaxVATDifference := LibraryRandom.RandDecInDecimalRange(0.1, 1, 2);
        // [GIVEN] "Allow VAT Difference" is enabled in Purchases Setup
        // [GIVEN] "Max VAT Difference" is 0.01 in General Ledger Setup
        SetAllowVATDifference(MaxVATDifference);
        // [GIVEN] Normal VAT Posting Setup with "VAT %" = 20 and Non-Deductible VAT %" = 100
        LibraryNonDeductibleVAT.CreateNonDeductibleNormalVATPostingSetup(VATPostingSetup);
        VATPostingSetup.Validate("Non-Deductible VAT %", 100);
        VATPostingSetup.Modify(true);
        // [GIVEN] Purchase invoice with amount = 100. VAT Amount = 20. Non-Deductible VAT Amount = 20
        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
            LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        LibraryPurchase.CreatePurchaseLineWithUnitCost(
            PurchaseLine, PurchaseHeader, LibraryInventory.CreateItemWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"),
            LibraryRandom.RandDec(100, 2), LibraryRandom.RandInt(100));
        VATAmount := PurchaseLine."Amount Including VAT" - PurchaseLine.Amount - MaxVATDifference;
        LibraryVariableStorage.Enqueue(VATAmount);
        LibraryVariableStorage.Enqueue(VATAmount);

        // [GIVEN] Open purchase invoice page
        PurchaseInvoicePage.OpenEdit();
        PurchaseInvoicePage.Filter.SetFilter("No.", PurchaseHeader."No.");
        // [GIVEN] Open statistics of the invoice
        PurchaseInvoicePage.Statistics.Invoke();

        // [WHEN] Set "VAT Amount" = 19.99
        // [THEN] "Non-Deductible VAT amount" is 19.99 on statistics page
        // [THEN] "Deductible Amount" is 0
        // Called in PurchaseStatisticsModalPageHandler

        PurchaseLine.Find();
        // [THEN] "VAT Difference" is -0.01 in the purchase line
        PurchaseLine.TestField("VAT Difference", -MaxVATDifference);
        // [THEN] "Amount Including VAT" is 119.99 in the purchase line
        PurchaseLine.TestField("Amount Including VAT", PurchaseLine.Amount + VATAmount);
        // [THEN] "Non-Deductible VAT" is 19.99 in the purchase line
        PurchaseLine.TestField("Non-Deductible VAT Amount", VATAmount);
        // [THEN] "Non-Deductible VAT Diff." is -0.01 in the purchase line
        PurchaseLine.TestField("Non-Deductible VAT Diff.", -MaxVATDifference);
        LibraryVariableStorage.AssertEmpty();
    end;
#endif

    [Test]
    [HandlerFunctions('PurchaseStatisticsChangeVATAmountPageHandler')]
    procedure ChangeNonDedVATAmtOnVATAmountChangeIfNDVATPctIs100()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoicePage: TestPage "Purchase Invoice";
        MaxVATDifference: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 456471] Non-Deductible VAT Amount is changed in statistics when Stan changes the VAT amount in case if "Non-Deductible VAT %" is 100

        Initialize();
        MaxVATDifference := LibraryRandom.RandDecInDecimalRange(0.1, 1, 2);
        // [GIVEN] "Allow VAT Difference" is enabled in Purchases Setup
        // [GIVEN] "Max VAT Difference" is 0.01 in General Ledger Setup
        SetAllowVATDifference(MaxVATDifference);
        // [GIVEN] Normal VAT Posting Setup with "VAT %" = 20 and Non-Deductible VAT %" = 100
        LibraryNonDeductibleVAT.CreateNonDeductibleNormalVATPostingSetup(VATPostingSetup);
        VATPostingSetup.Validate("Non-Deductible VAT %", 100);
        VATPostingSetup.Modify(true);
        // [GIVEN] Purchase invoice with amount = 100. VAT Amount = 20. Non-Deductible VAT Amount = 20
        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
            LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        LibraryPurchase.CreatePurchaseLineWithUnitCost(
            PurchaseLine, PurchaseHeader, LibraryInventory.CreateItemWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"),
            LibraryRandom.RandDec(100, 2), LibraryRandom.RandInt(100));
        VATAmount := PurchaseLine."Amount Including VAT" - PurchaseLine.Amount - MaxVATDifference;
        LibraryVariableStorage.Enqueue(VATAmount);
        LibraryVariableStorage.Enqueue(VATAmount);

        // [GIVEN] Open purchase invoice page
        PurchaseInvoicePage.OpenEdit();
        PurchaseInvoicePage.Filter.SetFilter("No.", PurchaseHeader."No.");
        // [GIVEN] Open statistics of the invoice
        PurchaseInvoicePage.PurchaseStatistics.Invoke();

        // [WHEN] Set "VAT Amount" = 19.99
        // [THEN] "Non-Deductible VAT amount" is 19.99 on statistics page
        // [THEN] "Deductible Amount" is 0
        // Called in PurchaseStatisticsModalPageHandler

        PurchaseLine.Find();
        // [THEN] "VAT Difference" is -0.01 in the purchase line
        PurchaseLine.TestField("VAT Difference", -MaxVATDifference);
        // [THEN] "Amount Including VAT" is 119.99 in the purchase line
        PurchaseLine.TestField("Amount Including VAT", PurchaseLine.Amount + VATAmount);
        // [THEN] "Non-Deductible VAT" is 19.99 in the purchase line
        PurchaseLine.TestField("Non-Deductible VAT Amount", VATAmount);
        // [THEN] "Non-Deductible VAT Diff." is -0.01 in the purchase line
        PurchaseLine.TestField("Non-Deductible VAT Diff.", -MaxVATDifference);
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Non-Deductible VAT Statistics");
        LibrarySetupStorage.Restore();
        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Non-Deductible VAT Statistics");
        LibraryNonDeductibleVAT.EnableNonDeductibleVAT();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibrarySetupStorage.Save(Database::"VAT Setup");
        LibrarySetupStorage.SavePurchasesSetup();
        LibrarySetupStorage.SaveGeneralLedgerSetup();
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Non-Deductible VAT Statistics");
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseStatisticsChangeNonDedVATAmountModalPageHandler')]
    procedure CannotSetNonDedVATAmtIfNotAllowedInVATPostingSetup()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoicePage: TestPage "Purchase Invoice";
        MaxVATDifference: Decimal;
        VATAmount: Decimal;
        NonDeductibleVATAmount: Decimal;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 456471] Stan cannot set "Non-Deductible VAT Amount" if Non-Deductible VAT is not allowed in the associated VAT Posting Setup
        //q1

        Initialize();
        MaxVATDifference := LibraryRandom.RandDecInDecimalRange(0.1, 1, 2);
        // [GIVEN] "Allow VAT Difference" is enabled in Purchases Setup
        // [GIVEN] "Max VAT Difference" is 0.01 in General Ledger Setup
        SetAllowVATDifference(MaxVATDifference);
        // [GIVEN] Normal VAT Posting Setup with "VAT %" = 20 and Non-Deductible VAT %" = 75. "Allow Non-Deductible VAT" is "Do Not Allow"
        LibraryNonDeductibleVAT.CreateNonDeductibleNormalVATPostingSetup(VATPostingSetup);
        VATPostingSetup.Validate("Allow Non-Deductible VAT", VATPostingSetup."Allow Non-Deductible VAT"::"Do Not Allow");
        VATPostingSetup.Modify(true);
        // [GIVEN] Purchase invoice with amount = 100. VAT Amount = 20. Non-Deductible VAT Amount = 20
        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
            LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        LibraryPurchase.CreatePurchaseLineWithUnitCost(
            PurchaseLine, PurchaseHeader, LibraryInventory.CreateItemWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"),
            LibraryRandom.RandDec(100, 2), LibraryRandom.RandInt(100));
        NonDeductibleVATAmount := PurchaseLine."Non-Deductible VAT Amount" + MaxVATDifference;
        VATAmount := PurchaseLine."Amount Including VAT" - PurchaseLine.Amount;

        LibraryVariableStorage.Enqueue(NonDeductibleVATAmount);
        LibraryVariableStorage.Enqueue(VATAmount);

        // [GIVEN] Open purchase invoice page
        PurchaseInvoicePage.OpenEdit();
        PurchaseInvoicePage.Filter.SetFilter("No.", PurchaseHeader."No.");
        // [WHEN] Open the statistics window
        PurchaseInvoicePage.Statistics.Invoke();

        // [THEN] "Non-Deductible VAT amount" is not editable on statistics page
        // Verifies in PurchaseStatisticsNonDedVATAmountNotEditableModalPageHandler

        LibraryVariableStorage.AssertEmpty();
    end;
#endif

    [Test]
    [HandlerFunctions('PurchaseStatisticsChangeNonDedVATAmountPageHandler')]
    procedure CannotSetNonDedVATAmountIfNotAllowedInVATPostingSetup()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoicePage: TestPage "Purchase Invoice";
        MaxVATDifference: Decimal;
        VATAmount: Decimal;
        NonDeductibleVATAmount: Decimal;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 456471] Stan cannot set "Non-Deductible VAT Amount" if Non-Deductible VAT is not allowed in the associated VAT Posting Setup
        //q1

        Initialize();
        MaxVATDifference := LibraryRandom.RandDecInDecimalRange(0.1, 1, 2);
        // [GIVEN] "Allow VAT Difference" is enabled in Purchases Setup
        // [GIVEN] "Max VAT Difference" is 0.01 in General Ledger Setup
        SetAllowVATDifference(MaxVATDifference);
        // [GIVEN] Normal VAT Posting Setup with "VAT %" = 20 and Non-Deductible VAT %" = 75. "Allow Non-Deductible VAT" is "Do Not Allow"
        LibraryNonDeductibleVAT.CreateNonDeductibleNormalVATPostingSetup(VATPostingSetup);
        VATPostingSetup.Validate("Allow Non-Deductible VAT", VATPostingSetup."Allow Non-Deductible VAT"::"Do Not Allow");
        VATPostingSetup.Modify(true);
        // [GIVEN] Purchase invoice with amount = 100. VAT Amount = 20. Non-Deductible VAT Amount = 20
        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
            LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        LibraryPurchase.CreatePurchaseLineWithUnitCost(
            PurchaseLine, PurchaseHeader, LibraryInventory.CreateItemWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"),
            LibraryRandom.RandDec(100, 2), LibraryRandom.RandInt(100));
        NonDeductibleVATAmount := PurchaseLine."Non-Deductible VAT Amount" + MaxVATDifference;
        VATAmount := PurchaseLine."Amount Including VAT" - PurchaseLine.Amount;

        LibraryVariableStorage.Enqueue(NonDeductibleVATAmount);
        LibraryVariableStorage.Enqueue(VATAmount);

        // [GIVEN] Open purchase invoice page
        PurchaseInvoicePage.OpenEdit();
        PurchaseInvoicePage.Filter.SetFilter("No.", PurchaseHeader."No.");
        // [WHEN] Open the statistics window
        PurchaseInvoicePage.PurchaseStatistics.Invoke();

        // [THEN] "Non-Deductible VAT amount" is not editable on statistics page
        // Verifies in PurchaseStatisticsNonDedVATAmountNotEditableModalPageHandler

        LibraryVariableStorage.AssertEmpty();
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseStatisticsChangeVATAmountModalPageHandler')]
    procedure PurchaseInvoiceInCurrencyIsPostedWhenChangeVATAmountOnStatisticIfNDVATPctIs100()
    var
        Currency: Record Currency;
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseInvoicePage: TestPage "Purchase Invoice";
        GenPostingType: Enum "General Posting Type";
        GLAccountNo: Code[20];
        ChangeVATAmount: Decimal;
    begin
        // [SCENARIO 560355] Purchase Invoice with currency code gets posted when Non-Deductible VAT is 100 Percent
        // And Non-Deductible VAT and the VAT Amount was previously modified in the Statistics.
        Initialize();

        // [GIVEN] "Allow VAT Difference" is enabled in Purchases Setup.
        LibraryPurchase.SetAllowVATDifference(true);

        // [GIVEN] Create Currency with Exchange Rate.
        CreateCurrencyWithExchangeRate(Currency);

        // [GIVEN] Set "Max. VAT Difference Allowed" in Currency.
        SetMaxVATDifferenceAllowInCurrency(LibraryRandom.RandIntInRange(1000, 1000), Currency);

        // [GIVEN] Generate VAT Amount to Change.
        ChangeVATAmount := LibraryRandom.RandIntInRange(150, 150);

        // [GIVEN] Create Normal VAT Posting Setup with "VAT %" = 20 and Non-Deductible VAT %" = 100.        
        LibraryNonDeductibleVAT.CreateVATPostingSetupWithNonDeductibleDetail(VATPostingSetup, 20, 100);

        // [GIVEN] Create a G/L Account.
        GLAccountNo := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GenPostingType::Purchase);

        // [GIVEN] Create a Purchase Invoice.
        CreatePurchaseInvoiceWithCurrencyCode(PurchaseHeader, VATPostingSetup."VAT Bus. Posting Group", Currency.Code, GLAccountNo);
        LibraryVariableStorage.Enqueue(ChangeVATAmount);
        LibraryVariableStorage.Enqueue(ChangeVATAmount);

        // [GIVEN] Open Purchase Invoice page.
        PurchaseInvoicePage.OpenEdit();
        PurchaseInvoicePage.Filter.SetFilter("No.", PurchaseHeader."No.");

        // [GIVEN] Open statistics of the invoice.
        PurchaseInvoicePage.Statistics.Invoke();

        // [WHEN] Purchase Invoice is Posted.
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        // [THEN] Verify G/L Entry is Consistent.
        VerifyGLEntryByDocumentNo(PurchInvHeader."No.", 0);
    end;
#endif

    [Test]
    [HandlerFunctions('PurchaseStatisticsChangeVATAmountPageHandler')]
    procedure PurchaseInvoiceInCurrencyIsPostedWhenChangeVATAmtOnStatisticIfNDVATPctIs100()
    var
        Currency: Record Currency;
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseInvoicePage: TestPage "Purchase Invoice";
        GenPostingType: Enum "General Posting Type";
        GLAccountNo: Code[20];
        ChangeVATAmount: Decimal;
    begin
        // [SCENARIO 560355] Purchase Invoice with currency code gets posted when Non-Deductible VAT is 100 Percent
        // And Non-Deductible VAT and the VAT Amount was previously modified in the Statistics.
        Initialize();

        // [GIVEN] "Allow VAT Difference" is enabled in Purchases Setup.
        LibraryPurchase.SetAllowVATDifference(true);

        // [GIVEN] Create Currency with Exchange Rate.
        CreateCurrencyWithExchangeRate(Currency);

        // [GIVEN] Set "Max. VAT Difference Allowed" in Currency.
        SetMaxVATDifferenceAllowInCurrency(LibraryRandom.RandIntInRange(1000, 1000), Currency);

        // [GIVEN] Generate VAT Amount to Change.
        ChangeVATAmount := LibraryRandom.RandIntInRange(150, 150);

        // [GIVEN] Create Normal VAT Posting Setup with "VAT %" = 20 and Non-Deductible VAT %" = 100.        
        LibraryNonDeductibleVAT.CreateVATPostingSetupWithNonDeductibleDetail(VATPostingSetup, 20, 100);

        // [GIVEN] Create a G/L Account.
        GLAccountNo := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GenPostingType::Purchase);

        // [GIVEN] Create a Purchase Invoice.
        CreatePurchaseInvoiceWithCurrencyCode(PurchaseHeader, VATPostingSetup."VAT Bus. Posting Group", Currency.Code, GLAccountNo);
        LibraryVariableStorage.Enqueue(ChangeVATAmount);
        LibraryVariableStorage.Enqueue(ChangeVATAmount);

        // [GIVEN] Open Purchase Invoice page.
        PurchaseInvoicePage.OpenEdit();
        PurchaseInvoicePage.Filter.SetFilter("No.", PurchaseHeader."No.");

        // [GIVEN] Open statistics of the invoice.
        PurchaseInvoicePage.PurchaseStatistics.Invoke();

        // [WHEN] Purchase Invoice is Posted.
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        // [THEN] Verify G/L Entry is Consistent.
        VerifyGLEntryByDocumentNo(PurchInvHeader."No.", 0);
    end;

    local procedure SetAllowVATDifference(MaxVATDifference: Decimal)
    var
        PurchasesSetup: Record "Purchases & Payables Setup";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        PurchasesSetup.Get();
        PurchasesSetup.Validate("Allow VAT Difference", true);
        PurchasesSetup.Modify(true);
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Max. VAT Difference Allowed", MaxVATDifference);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure FindVATEntry(var VATEntry: Record "VAT Entry"; DocumentNo: Code[20])
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange("Posting Date", WorkDate());
        VATEntry.FindFirst();
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; GLAccNo: Code[20]; ExpectedCount: Integer; ExpectedAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Posting Date", WorkDate());
        GLEntry.SetRange("G/L Account No.", GLAccNo);
        Assert.RecordCount(GLEntry, ExpectedCount);
        GLEntry.CalcSums(Amount);
        GLEntry.TestField(Amount, ExpectedAmount);
    end;

    local procedure CreateCurrencyWithExchangeRate(var Currency: Record Currency)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        Currency.Get(LibraryERM.CreateCurrencyWithGLAccountSetup());

        LibraryERM.CreateExchRate(CurrencyExchangeRate, Currency.Code, WorkDate());
        CurrencyExchangeRate.Validate("Exchange Rate Amount", LibraryRandom.RandInt(0));
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", LibraryRandom.RandInt(0));
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", LibraryRandom.RandDecInDecimalRange(0.6458, 0.6458, 4));
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", LibraryRandom.RandDecInDecimalRange(0.6458, 0.6458, 4));
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure SetMaxVATDifferenceAllowInCurrency(MaxVATDifference: Decimal; Currency: Record Currency)
    begin
        Currency.Validate("Max. VAT Difference Allowed", MaxVATDifference);
        Currency.Modify(true);
    end;

    local procedure CreatePurchaseInvoiceWithCurrencyCode(
        var PurchaseHeader: Record "Purchase Header";
        VATBusPostingGroup: Code[20];
        CurrencyCode: Code[20];
        GLAccountNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);

        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader,
            PurchaseHeader."Document Type"::Invoice,
            LibraryPurchase.CreateVendorWithBusPostingGroups(GeneralPostingSetup."Gen. Bus. Posting Group", VATBusPostingGroup));
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Modify(true);

        GLAccount.Get(GLAccountNo);
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Modify(true);

        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine,
            PurchaseHeader,
            PurchaseLine.Type::"G/L Account",
            GLAccountNo,
            LibraryRandom.RandInt(0));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(1000, 1000));
        PurchaseLine.Modify(true);
    end;

    local procedure VerifyGLEntryByDocumentNo(DocumentNo: Code[20]; ExpectedAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.CalcSums(Amount);
        Assert.AreEqual(ExpectedAmount, GLEntry.Amount, GLEntryConsistentErr);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [ModalPageHandler]
    procedure PurchaseStatisticsChangeVATAmountModalPageHandler(var PurchaseStatisticsPage: TestPage "Purchase Statistics")
    var
        VATAmount: Decimal;
        NonDeductibleVATAmount: Decimal;
    begin
        NonDeductibleVATAmount := LibraryVariableStorage.DequeueDecimal();
        VATAmount := LibraryVariableStorage.DequeueDecimal();
        PurchaseStatisticsPage.SubForm."VAT Amount".SetValue(VATAmount);
        PurchaseStatisticsPage.SubForm.NonDeductibleAmount.AssertEquals(NonDeductibleVATAmount);
        PurchaseStatisticsPage.SubForm.DeductibleAmount.AssertEquals(VATAmount - NonDeductibleVATAmount);
    end;
#endif

    [PageHandler]
    procedure PurchaseStatisticsChangeVATAmountPageHandler(var PurchaseStatisticsPage: TestPage "Purchase Statistics")
    var
        VATAmount: Decimal;
        NonDeductibleVATAmount: Decimal;
    begin
        NonDeductibleVATAmount := LibraryVariableStorage.DequeueDecimal();
        VATAmount := LibraryVariableStorage.DequeueDecimal();
        PurchaseStatisticsPage.SubForm."VAT Amount".SetValue(VATAmount);
        PurchaseStatisticsPage.SubForm.NonDeductibleAmount.AssertEquals(NonDeductibleVATAmount);
        PurchaseStatisticsPage.SubForm.DeductibleAmount.AssertEquals(VATAmount - NonDeductibleVATAmount);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [ModalPageHandler]
    procedure PurchaseStatisticsChangeNonDedVATAmountModalPageHandler(var PurchaseStatisticsPage: TestPage "Purchase Statistics")
    var
        VATAmount: Decimal;
        NonDeductibleVATAmount: Decimal;
    begin
        NonDeductibleVATAmount := LibraryVariableStorage.DequeueDecimal();
        VATAmount := LibraryVariableStorage.DequeueDecimal();
        PurchaseStatisticsPage.SubForm.NonDeductibleAmount.SetValue(NonDeductibleVATAmount);
        PurchaseStatisticsPage.SubForm."VAT Amount".AssertEquals(VATAmount);
        PurchaseStatisticsPage.SubForm.DeductibleAmount.AssertEquals(VATAmount - NonDeductibleVATAmount);
    end;
#endif

    [PageHandler]
    procedure PurchaseStatisticsChangeNonDedVATAmountPageHandler(var PurchaseStatisticsPage: TestPage "Purchase Statistics")
    var
        VATAmount: Decimal;
        NonDeductibleVATAmount: Decimal;
    begin
        NonDeductibleVATAmount := LibraryVariableStorage.DequeueDecimal();
        VATAmount := LibraryVariableStorage.DequeueDecimal();
        PurchaseStatisticsPage.SubForm.NonDeductibleAmount.SetValue(NonDeductibleVATAmount);
        PurchaseStatisticsPage.SubForm."VAT Amount".AssertEquals(VATAmount);
        PurchaseStatisticsPage.SubForm.DeductibleAmount.AssertEquals(VATAmount - NonDeductibleVATAmount);
    end;

    [ModalPageHandler]
    procedure PurchaseStatisticsNonDedVATAmountNotEditableModalPageHandler(var PurchaseStatisticsPage: TestPage "Purchase Statistics")
    begin
        Assert.IsFalse(PurchaseStatisticsPage.SubForm.NonDeductibleAmount.Editable(), 'It is possible to change Non-Deductible VAT Amount');
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [ModalPageHandler]
    procedure PurchaseStatisticsChangeVATAmtAndNonDedVATAmtModalPageHandler(var PurchaseStatisticsPage: TestPage "Purchase Statistics")
    var
        VATAmount: Decimal;
        NonDeductibleVATAmount: Decimal;
    begin
        NonDeductibleVATAmount := LibraryVariableStorage.DequeueDecimal();
        VATAmount := LibraryVariableStorage.DequeueDecimal();
        PurchaseStatisticsPage.SubForm.NonDeductibleAmount.SetValue(NonDeductibleVATAmount);
        PurchaseStatisticsPage.SubForm."VAT Amount".SetValue(VATAmount);
        PurchaseStatisticsPage.SubForm.DeductibleAmount.AssertEquals(VATAmount - NonDeductibleVATAmount);
    end;
#endif

    [PageHandler]
    procedure PurchaseStatisticsChangeVATAmtAndNonDedVATAmtPageHandler(var PurchaseStatisticsPage: TestPage "Purchase Statistics")
    var
        VATAmount: Decimal;
        NonDeductibleVATAmount: Decimal;
    begin
        NonDeductibleVATAmount := LibraryVariableStorage.DequeueDecimal();
        VATAmount := LibraryVariableStorage.DequeueDecimal();
        PurchaseStatisticsPage.SubForm.NonDeductibleAmount.SetValue(NonDeductibleVATAmount);
        PurchaseStatisticsPage.SubForm."VAT Amount".SetValue(VATAmount);
        PurchaseStatisticsPage.SubForm.DeductibleAmount.AssertEquals(VATAmount - NonDeductibleVATAmount);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [ModalPageHandler]
    procedure PurchaseStatisticsChangeVATAmtAndNonDedVATAmtOrVerifyModalPageHandler(var PurchaseStatisticsPage: TestPage "Purchase Statistics")
    var
        VerifyMode: Boolean;
        VATAmount: Decimal;
        NonDeductibleVATAmount: Decimal;
    begin
        VerifyMode := LibraryVariableStorage.DequeueBoolean();
        NonDeductibleVATAmount := LibraryVariableStorage.DequeueDecimal();
        VATAmount := LibraryVariableStorage.DequeueDecimal();
        if VerifyMode then begin
            PurchaseStatisticsPage.SubForm.NonDeductibleAmount.AssertEquals(NonDeductibleVATAmount);
            PurchaseStatisticsPage.SubForm."VAT Amount".AssertEquals(VATAmount);
            PurchaseStatisticsPage.SubForm.DeductibleAmount.AssertEquals(VATAmount - NonDeductibleVATAmount);
        end else begin
            PurchaseStatisticsPage.SubForm.NonDeductibleAmount.SetValue(NonDeductibleVATAmount);
            PurchaseStatisticsPage.SubForm."VAT Amount".SetValue(VATAmount);
        end;
    end;
#endif  

    [PageHandler]
    procedure PurchaseStatisticsChangeVATAmtAndNonDedVATAmtOrVerifyPageHandler(var PurchaseStatisticsPage: TestPage "Purchase Statistics")
    var
        VerifyMode: Boolean;
        VATAmount: Decimal;
        NonDeductibleVATAmount: Decimal;
    begin
        VerifyMode := LibraryVariableStorage.DequeueBoolean();
        NonDeductibleVATAmount := LibraryVariableStorage.DequeueDecimal();
        VATAmount := LibraryVariableStorage.DequeueDecimal();
        if VerifyMode then begin
            PurchaseStatisticsPage.SubForm.NonDeductibleAmount.AssertEquals(NonDeductibleVATAmount);
            PurchaseStatisticsPage.SubForm."VAT Amount".AssertEquals(VATAmount);
            PurchaseStatisticsPage.SubForm.DeductibleAmount.AssertEquals(VATAmount - NonDeductibleVATAmount);
        end else begin
            PurchaseStatisticsPage.SubForm.NonDeductibleAmount.SetValue(NonDeductibleVATAmount);
            PurchaseStatisticsPage.SubForm."VAT Amount".SetValue(VATAmount);
        end;
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [ModalPageHandler]
    procedure PurchaseOrderStatisticsDrillDownInvLinesModalPageHandler(var PurchaseOrderStatisticsPage: TestPage "Purchase Order Statistics")
    begin
        PurchaseOrderStatisticsPage.NoOfVATLines_Invoicing.Drilldown();
    end;
#endif

    [PageHandler]
    procedure PurchaseOrderStatisticsDrillDownInvLinesPageHandler(var PurchaseOrderStatisticsPage: TestPage "Purchase Order Statistics")
    begin
        PurchaseOrderStatisticsPage.NoOfVATLines_Invoicing.Drilldown();
    end;

    [ModalPageHandler]
    procedure VATAmountLinesCheckOrVerifyNonDedVATAmtModalPageHandler(var VATAmountLinesPage: TestPage "VAT Amount Lines")
    var
        VerifyMode: Boolean;
        VATAmount: Decimal;
        NonDeductibleVATAmount: Decimal;
    begin
        VerifyMode := LibraryVariableStorage.DequeueBoolean();
        NonDeductibleVATAmount := LibraryVariableStorage.DequeueDecimal();
        VATAmount := LibraryVariableStorage.DequeueDecimal();
        if VerifyMode then begin
            VATAmountLinesPage."VAT Amount".AssertEquals(VATAmount);
            VATAmountLinesPage.NonDeductibleAmount.AssertEquals(NonDeductibleVATAmount);
            VATAmountLinesPage.DeductibleAmount.AssertEquals(VATAmount - NonDeductibleVATAmount);
        end else begin
            VATAmountLinesPage.NonDeductibleAmount.SetValue(NonDeductibleVATAmount);
            VATAmountLinesPage."VAT Amount".SetValue(VATAmount);
        end;
    end;
}