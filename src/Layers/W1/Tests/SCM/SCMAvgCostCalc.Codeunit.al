codeunit 137070 "SCM Avg. Cost Calc."
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Cost Average] [SCM]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryERM: Codeunit "Library - ERM";
        LibraryJob: Codeunit "Library - Job";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        IsInitialized: Boolean;
        IncorrectAverageCostErr: Label 'Average Cost is incorrect.';
        IncorrectAverageCostACYErr: Label 'Average Cost (ACY) is incorrect.';

    [Test]
    [Scope('OnPrem')]
    procedure TestBug270797_UsingSales()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        InventorySetup: Record "Inventory Setup";
    begin
        // [SCENARIO] Average Cost Period: Day, Average Cost Calc. Type: Item, verify expected Cost after posting: purchase - sale - negative purchase - undo negative purchase - adjust cost - sale - adjust cost.

        Initialize();
        InvtSetup(InventorySetup."Average Cost Period"::Day, InventorySetup."Average Cost Calc. Type"::Item);
        CreateItem(Item);
        PostPurch(Item, '', WorkDate(), 142.7, 8.458);
        PostSaleOrder(Item, '', WorkDate(), 132.5, true, true, '');
        PostNegPurch(Item, PurchaseLine, '', -28.7);
        UndoNegPurch(PurchaseLine);
        AdjustCost(Item);
        PostSaleOrder(Item, '', WorkDate(), 3.9, true, true, '');
        AdjustCost(Item);
        VerifyExpectedCostunit(Item."No.", 8.458, 0.001);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBug270797_UsingTransfer()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        InventorySetup: Record "Inventory Setup";
    begin
        // [SCENARIO] Average Cost Period: Day, Average Cost Calc. Type: Item & Location & Variant, verify expected Cost after posting: purchase - transfer - negative purchase - undo negative purchase - adjust cost - sale - adjust cost.

        Initialize();
        InvtSetup(InventorySetup."Average Cost Period"::Day, InventorySetup."Average Cost Calc. Type"::"Item & Location & Variant");
        CreateItem(Item);
        PostPurch(Item, '', WorkDate(), 142.7, 8.458);
        PostTrans(Item, '', SelectLocBlue(), 132.5);
        PostNegPurch(Item, PurchaseLine, '', -28.7);
        UndoNegPurch(PurchaseLine);
        AdjustCost(Item);
        PostSaleOrder(Item, SelectLocBlue(), WorkDate(), 3.9, true, true, '');
        AdjustCost(Item);
        VerifyExpectedCostunit(Item."No.", 8.458, 0.001);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBug270797NegativeStart()
    var
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        InventorySetup: Record "Inventory Setup";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        i: Integer;
        TotalCost: Decimal;
    begin
        // [FEATURE] [Item Journal]
        // [SCENARIO] Average Cost Period: Day, Average Cost Calc. Type: Item, verify Total Cost in ILEs after post: purchase (Qty = X*3) - three sales (Qty = X), then Adjust Cost.

        Initialize();
        InvtSetup(InventorySetup."Average Cost Period"::Day, InventorySetup."Average Cost Calc. Type"::Item);
        CreateItem(Item);

        ItemJnlLine.Init();
        ItemJnlLine.Validate("Document No.", 'my no');  // find a number
        ItemJnlLine.Validate("Posting Date", WorkDate());
        ItemJnlLine.Validate("Item No.", Item."No.");
        ItemJnlLine.Validate(Quantity, 3);
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Purchase);
        ItemJnlLine.Validate(Amount, 10);

        ItemJnlPostLine.RunWithCheck(ItemJnlLine);

        for i := 1 to 3 do begin
            ItemJnlLine.Init();
            ItemJnlLine.Validate("Document No.", 'my no');
            ItemJnlLine.Validate("Posting Date", WorkDate());
            ItemJnlLine.Validate("Item No.", Item."No.");
            ItemJnlLine.Validate(Quantity, 1);
            ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Sale);

            ItemJnlPostLine.RunWithCheck(ItemJnlLine);
        end;

        AdjustCost(Item);

        // VERIFYCATION
        ItemLedgerEntry.SetCurrentKey("Item No.");
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        if ItemLedgerEntry.FindSet() then
            repeat
                ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
                TotalCost += ItemLedgerEntry."Cost Amount (Actual)";
            until ItemLedgerEntry.Next() = 0;

        Assert.AreEqual(0, TotalCost, '');
        // entry no   Cost per unit            Cost amount              qty
        // 734     3,33333000000000000000 10,00000000000000000000  3,00000000000000000000
        // 735     0,00000000000000000000 0,00000000000000000000  -1,00000000000000000000
        // 736     0,00000000000000000000 0,00000000000000000000  -1,00000000000000000000
        // 737     0,00000000000000000000 0,00000000000000000000  -1,00000000000000000000
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBug292444_ReproSteps()
    var
        Item: Record Item;
        InventorySetup: Record "Inventory Setup";
        QtyRevalued: Decimal;
        InbndQty: Decimal;
        InbndQtyLeftOnInventory: Decimal;
        InbndDate: Date;
        ShipOutbndQty: Decimal;
        ShipOutbndDate: Date;
        UnitCost: Decimal;
        UnitCostRevaluedInitial: Decimal;
    begin
        // [FEATURE] [Revaluation]
        // [SCENARIO] Verify that can run Revaluation in chain: purchase(day 1) - ship sales(day 2) - adjust cost - revaluate(day 2).

        // Bug 292444 Calculate Inventory Value batch doesn't work because of fix 268295
        // Scenario: Revaluation should be allowed for an inbnd ILE even it has one ore more otbnd entries not invoiced

        // Setup test
        Initialize();
        InvtSetup(InventorySetup."Average Cost Period"::Day, InventorySetup."Average Cost Calc. Type"::Item);
        CreateItem(Item); // Step 1

        // Steps
        // Day 1
        InbndDate := WorkDate();
        InbndQty := 10;
        UnitCost := 100;
        PostPurch(Item, '', InbndDate, InbndQty, UnitCost); // Step 2 & 3 Inbnd entry shipped and invoiced to be revaluated

        // Day 2
        InbndQtyLeftOnInventory := 1;
        ShipOutbndDate := CalcDate('<1D>', InbndDate);
        ShipOutbndQty := InbndQty - InbndQtyLeftOnInventory;
        PostSaleOrder(Item, '', ShipOutbndDate, ShipOutbndQty, true, false, ''); // Step 4 & 5 Ship Sales Order = outbnd not invoiced

        AdjustCost(Item); // Step 6
        UnitCostRevaluedInitial := 1200;
        CalcAndPostRevaluation(Item, ShipOutbndDate, UnitCostRevaluedInitial, QtyRevalued); // Step 7
        // Actual Result from bug: An error is thrown - "...cannot be revalued because there is at least one not completely invoiced Item Ledger Entry."
        // Expected result is that Calculate Inventory Value batch can run in Step 7

        // Regresion introduced in bug 268295
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBug207612_ReproSteps()
    var
        Item: Record Item;
        InventorySetup: Record "Inventory Setup";
        SODocNo: Code[20];
        InbndQty: Decimal;
        QtyRevalued: Decimal;
        InbndDate: Date;
        ShipOutbndQty: Decimal;
        ShipOutbndDate: Date;
        InvOutbndQty: Decimal;
        InvOutbndDate: Date;
        UnitCost: Decimal;
        UnitCostRevaluedInitial: Decimal;
        UnitCostRevaluedFinal: Decimal;
    begin
        // [SCENARIO 57537] Verify Cost in Item after run Adjust Cost, after chain: purchase(day 1) - ship sale(day 2) - adjust cost - revaluate(day 2) - invoice sale (previous, day 3) - adjust cost - revaluate(day 3).

        // Unit cost on item card demonstrate a negative amount,
        // probably due to an incorrect revaluable quantity in a Revaluation journal earlier in the process.

        // Scenario: Revaluation of an inbnd ILE is allowed even it has one ore more otbnd entries not invoiced. However if
        // Revaluation is made in this case it should not be forwarded to outbnd entries not invoiced at the time of revaluation since
        // revaluation is done on qty on inventory.

        // Setup test
        Initialize();
        InvtSetup(InventorySetup."Average Cost Period"::Day, InventorySetup."Average Cost Calc. Type"::Item);
        CreateItem(Item); // Step 1

        // Steps
        // Day 1
        InbndDate := WorkDate();
        InbndQty := 10;
        UnitCost := 100;
        PostPurch(Item, '', InbndDate, InbndQty, UnitCost); // Step 2 & 3 Inbnd entry shipped and invoiced to be revaluated

        // Day 2
        ShipOutbndDate := CalcDate('<1D>', InbndDate);
        ShipOutbndQty := 9;
        SODocNo := PostSaleOrder(Item, '', ShipOutbndDate, ShipOutbndQty, true, false, ''); // Step 4 & 5 Ship Sales Order = outbnd not invoiced

        AdjustCost(Item); // Step 6
        UnitCostRevaluedInitial := 1200;
        CalcAndPostRevaluation(Item, ShipOutbndDate, UnitCostRevaluedInitial, QtyRevalued); // Step 7 Revaluate
        Assert.AreEqual(InbndQty - ShipOutbndQty, QtyRevalued, 'The quantity to revalue should be InboundQty - OutboundQty)');

        // Day 3
        InvOutbndDate := CalcDate('<2D>', InbndDate);
        InvOutbndQty := ShipOutbndQty;
        PostSaleOrder(Item, '', InvOutbndDate, InvOutbndQty, false, true, SODocNo); // Step 8 & 9 Invoice Sales Order shipped earlier - previos outbnd now invoiced

        AdjustCost(Item); // Step 10
        UnitCostRevaluedFinal := 120;
        CalcAndPostRevaluation(Item, InvOutbndDate, UnitCostRevaluedFinal, QtyRevalued); // Step 11 Revaluate
        Assert.AreEqual(InbndQty - ShipOutbndQty, QtyRevalued, 'The quantity to revalue should be InboundQty - OutboundQty)');

        // Not needed: PostSaleOrder(Item,'',InvOutbndDate,InbndQtyLeftOnInventory,TRUE,TRUE,''); // Step 12 Ship & Invoice Sales Order of remaining qty on inventory
        AdjustCost(Item); // Step 13

        // Verification
        VerifyItemUnitCost(Item."No.", UnitCostRevaluedFinal); // Actual result from bug: -8580
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBug207612_ReproSteps_MoveRevalDateToInbndDate()
    var
        Item: Record Item;
        InventorySetup: Record "Inventory Setup";
        QtyRevalued: Decimal;
        SODocNo: Code[20];
        InbndQty: Decimal;
        InbndDate: Date;
        ShipOutbndQty: Decimal;
        ShipOutbndDate: Date;
        InvOutbndQty: Decimal;
        InvOutbndDate: Date;
        UnitCost: Decimal;
        UnitCostRevaluedInitial: Decimal;
        UnitCostRevaluedFinal: Decimal;
    begin
        // [SCENARIO] Verify Cost in Item after run Adjust Cost, after chain: purchase(day 1) - ship sale(day 2) - adjust cost - revaluate(day 1) - invoice sale (previous, day 3) - adjust cost - revaluate(day 3).

        // As TestBug207612_ReproSteps except using Inbnd date (and InbndQty) in step 6 to revalue the entire purchased quantity from step 2 & 3
        // This is to test that not only Entry No is used in Adjustment of revaluation but alse Date of revaluation is taken into account

        // Setup test
        Initialize();
        InvtSetup(InventorySetup."Average Cost Period"::Day, InventorySetup."Average Cost Calc. Type"::Item);
        CreateItem(Item); // Step 1

        // Steps
        // Day 1
        InbndDate := WorkDate();
        InbndQty := 10;
        UnitCost := 100;
        PostPurch(Item, '', InbndDate, InbndQty, UnitCost); // Step 2 & 3 Inbnd entry shipped and invoiced to be revaluated

        // Day 2
        ShipOutbndDate := CalcDate('<1D>', InbndDate);
        ShipOutbndQty := 9;
        SODocNo := PostSaleOrder(Item, '', ShipOutbndDate, ShipOutbndQty, true, false, ''); // Step 4 & 5 Ship Sales Order = outbnd not invoiced

        AdjustCost(Item); // Step 6
        UnitCostRevaluedInitial := 1200;
        // Use Inbnd date (and InbndQty)
        CalcAndPostRevaluation(Item, InbndDate, UnitCostRevaluedInitial, QtyRevalued); // Step 7 Revaluate
        Assert.AreEqual(InbndQty, QtyRevalued, 'The quantity to revalue should be InboundQty');

        // Day 3
        InvOutbndDate := CalcDate('<2D>', InbndDate);
        InvOutbndQty := ShipOutbndQty;
        PostSaleOrder(Item, '', InvOutbndDate, InvOutbndQty, false, true, SODocNo); // Step 8 & 9 Invoice Sales Order shipped earlier - previos outbnd now invoiced

        AdjustCost(Item); // Step 10
        UnitCostRevaluedFinal := 120;
        CalcAndPostRevaluation(Item, InvOutbndDate, UnitCostRevaluedFinal, QtyRevalued); // Step 11 Revaluate
        Assert.AreEqual(InbndQty - ShipOutbndQty, QtyRevalued, 'The quantity to revalue should be InboundQty - OutboundQty)');

        // Not needed: PostSaleOrder(Item,'',InvOutbndDate,InbndQtyLeftOnInventory,TRUE,TRUE,''); // Step 12 Ship & Invoice Sales Order of remaining qty on inventory
        AdjustCost(Item); // Step 13

        // Verification
        VerifyItemUnitCost(Item."No.", UnitCostRevaluedFinal); // Actual result from bug: -8580
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AverageCostWhenSumOfCostIsEqualToRoundingPrecision()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Item: Record Item;
        ItemCostMgt: Codeunit ItemCostManagement;
        ExpectedAverageCost: Decimal;
        ExpectedAverageCostACY: Decimal;
        AverageCost: Decimal;
        AverageCostACY: Decimal;
    begin
        // [FEATURE] [Average Cost] [UT]
        // [SCENARIO 380304] In case sum of Cost Amount for Item is equal to rounding precision of a local currency, the Average Cost is equal to precise remaining Cost divided by remaining Quantity.
        Initialize();
        GeneralLedgerSetup.Get();
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Fully applied positive and negative Item entries "E1+" and "E1-".
        // [GIVEN] There is no difference between Cost Amounts of "E1+" and "E1-" as the cost is considered to have been adjusted.
        PostPositiveAndNegativeAdjustments(Item."No.", 0, 0, 0);

        // [GIVEN] Partially applied positive and negative Item entries "E2+" and "E2-".
        // [GIVEN] Difference between Cost Amounts of "E2+" and "E2-" is equal to the rounding precision of a local currency.
        PostPositiveAndNegativeAdjustments(
          Item."No.", LibraryRandom.RandInt(5), GeneralLedgerSetup."Amount Rounding Precision", 0);

        // [WHEN] Calculate Average Cost.
        ItemCostMgt.CalculateAverageCost(Item, AverageCost, AverageCostACY);

        // [THEN] Average Cost is equal to unit cost of the open positive Item entry "E2+".
        CalcOpenItemLedgerEntriesAverageUnitCosts(Item."No.", ExpectedAverageCost, ExpectedAverageCostACY);
        Assert.AreNearlyEqual(
          ExpectedAverageCost, AverageCost, GeneralLedgerSetup."Amount Rounding Precision", IncorrectAverageCostErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AverageCostACYWhenSumOfCostIsEqualToRoundingPrecision()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Item: Record Item;
        Currency: Record Currency;
        ItemCostMgt: Codeunit ItemCostManagement;
        OldACYCode: Code[10];
        ExpectedAverageCost: Decimal;
        ExpectedAverageCostACY: Decimal;
        AverageCost: Decimal;
        AverageCostACY: Decimal;
    begin
        // [FEATURE] [Average Cost] [UT]
        // [SCENARIO 380304] In case sum of Cost Amount in an additional reporting currency (ACY) for Item is equal to rounding precision of ACY, the Average Cost in ACY is equal to precise remaining Cost divided by remaining Quantity.
        Initialize();
        CreateCurrencyWithRoundingPrecision(Currency);
        OldACYCode := UpdateAdditionalReportingCurrencyInGLSetup(GeneralLedgerSetup, Currency.Code);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Fully applied positive and negative Item entries "E1+" and "E1-".
        // [GIVEN] There is no difference between Cost Amounts (ACY) of "E1+" and "E1-" as the cost is considered to have been adjusted.
        PostPositiveAndNegativeAdjustments(Item."No.", 0, 0, 0);

        // [GIVEN] Partially applied positive and negative Item entries "E2+" and "E2-".
        // [GIVEN] Difference between Cost Amounts (ACY) of "E2+" and "E2-" is equal to the rounding precision of the ACY.
        PostPositiveAndNegativeAdjustments(
          Item."No.", LibraryRandom.RandInt(5), 0, Currency."Amount Rounding Precision");

        // [WHEN] Calculate Average Cost.
        ItemCostMgt.CalculateAverageCost(Item, AverageCost, AverageCostACY);

        // [THEN] Average Cost is equal to unit cost (ACY) of the open positive Item entry "E2+".
        CalcOpenItemLedgerEntriesAverageUnitCosts(Item."No.", ExpectedAverageCost, ExpectedAverageCostACY);
        Assert.AreNearlyEqual(
          ExpectedAverageCostACY, AverageCostACY, Currency."Amount Rounding Precision", IncorrectAverageCostACYErr);

        // restore ACY in General Ledger Setup
        UpdateAdditionalReportingCurrencyInGLSetup(GeneralLedgerSetup, OldACYCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AverageCostWhenSumOfCostIsGreaterThanRoundingPrecision()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Item: Record Item;
        ItemCostMgt: Codeunit ItemCostManagement;
        ExpectedAverageCost: Decimal;
        ExpectedAverageCostACY: Decimal;
        AverageCost: Decimal;
        AverageCostACY: Decimal;
    begin
        // [FEATURE] [Average Cost] [UT]
        // [SCENARIO 380304] In case sum of Cost Amount for Item is greater than rounding precision of a local currency, the Average Cost is equal to the sum of cost divided by the sum of quantity of posted entries.
        Initialize();
        GeneralLedgerSetup.Get();
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Fully applied positive and negative Item entries "E1+" and "E1-".
        // [GIVEN] There is no difference between Cost Amounts of "E1+" and "E1-" as the cost is considered to have been adjusted.
        PostPositiveAndNegativeAdjustments(Item."No.", 0, 0, 0);

        // [GIVEN] Partially applied positive and negative Item entries "E2+" and "E2-".
        // [GIVEN] Difference between Cost Amounts of "E2+" and "E2-" is greater than the rounding precision of a local currency.
        PostPositiveAndNegativeAdjustments(
          Item."No.", LibraryRandom.RandInt(5),
          GeneralLedgerSetup."Amount Rounding Precision" + LibraryRandom.RandInt(5), 0);

        // [WHEN] Calculate Average Cost.
        ItemCostMgt.CalculateAverageCost(Item, AverageCost, AverageCostACY);

        // [THEN] Average Cost is equal to the sum of cost divided by the sum of quantity of all entries "E1+", "E2+", "E1-", "E2-".
        CalcBulkAverageUnitCosts(Item."No.", ExpectedAverageCost, ExpectedAverageCostACY);
        Assert.AreNearlyEqual(
          ExpectedAverageCost, AverageCost, GeneralLedgerSetup."Amount Rounding Precision", IncorrectAverageCostErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AverageCostACYWhenSumOfCostIsGreaterThanRoundingPrecision()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Item: Record Item;
        Currency: Record Currency;
        ItemCostMgt: Codeunit ItemCostManagement;
        OldACYCode: Code[10];
        ExpectedAverageCost: Decimal;
        ExpectedAverageCostACY: Decimal;
        AverageCost: Decimal;
        AverageCostACY: Decimal;
    begin
        // [FEATURE] [Average Cost] [UT]
        // [SCENARIO 380304] In case sum of Cost Amount in an additional reporting currency (ACY) for Item is greater than the rounding precision of ACY, the Average Cost in ACY is equal to the sum of cost (ACY) divided by the sum of quantity.
        Initialize();
        CreateCurrencyWithRoundingPrecision(Currency);
        OldACYCode := UpdateAdditionalReportingCurrencyInGLSetup(GeneralLedgerSetup, Currency.Code);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Fully applied positive and negative Item entries "E1+" and "E1-".
        // [GIVEN] There is no difference between Cost Amounts (ACY) of "E1+" and "E1-" as the cost is considered to have been adjusted.
        PostPositiveAndNegativeAdjustments(Item."No.", 0, 0, 0);

        // [GIVEN] Partially applied positive and negative Item entries "E2+" and "E2-".
        // [GIVEN] Difference between Cost Amounts (ACY) of "E2+" and "E2-" is greater than the rounding precision of the ACY.
        PostPositiveAndNegativeAdjustments(
          Item."No.", LibraryRandom.RandInt(5), 0,
          Currency."Amount Rounding Precision" + LibraryRandom.RandInt(5));

        // [WHEN] Calculate Average Cost.
        ItemCostMgt.CalculateAverageCost(Item, AverageCost, AverageCostACY);

        // [THEN] Average Cost is equal to the sum of cost (ACY) divided by the sum of quantity of all entries "E1+", "E2+", "E1-", "E2-".
        CalcBulkAverageUnitCosts(Item."No.", ExpectedAverageCost, ExpectedAverageCostACY);
        Assert.AreNearlyEqual(
          ExpectedAverageCostACY, AverageCostACY, Currency."Amount Rounding Precision", IncorrectAverageCostACYErr);

        // restore ACY in General Ledger Setup
        UpdateAdditionalReportingCurrencyInGLSetup(GeneralLedgerSetup, OldACYCode);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure AvgCostAdjmtEntryPointCostIsAdjustedFALSEAfterUndoPurchaseReceiptLine()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        AvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point";
    begin
        // [FEATURE] [Undo Purchase]
        // [SCENARIO 263366] "Avg. Cost Adjmt. Entry Point"."Cost Is Adjusted" is FALSE after undo purchase receipt line for item with "Costing Method" = Average
        Initialize();

        // [GIVEN] Item "I" with "Costing Method" = Average
        CreateItem(Item);

        // [GIVEN] Posted purchase receipt of "I"
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', Item."No.", LibraryRandom.RandInt(10), '', WorkDate());
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Adjust cost item entries of "I"
        AdjustCost(Item);

        // [WHEN] Undo the purchase receipt line of "I"
        FindPurchRcptLine(PurchRcptLine, PurchaseHeader."No.");
        LibraryPurchase.UndoPurchaseReceiptLine(PurchRcptLine);

        // [THEN] The field "Cost Is Adjusted" in the table "Avg. Cost Adjmt. Entry Point" for "I" is FALSE
        FindAvgCostAdjmtEntryPoint(AvgCostAdjmtEntryPoint, Item."No.");
        AvgCostAdjmtEntryPoint.TestField("Cost Is Adjusted", false);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure JobConsumptionEntryFixAppliedToPurchase()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // [FEATURE] [Job]
        // [SCENARIO 262595] Job consumption item ledger entry should be posted with fixed application to the purchase entry without item tracking

        Initialize();

        // [GIVEN] Purchase 10 pcs of item "I", "Unit Cost" = 100
        CreateItem(Item);
        PostPurch(Item, '', WorkDate(), LibraryRandom.RandIntInRange(10, 20), LibraryRandom.RandIntInRange(100, 200));

        // [GIVEN] Post a purchase order with linked job for the same item "I", "Unit Cost" = 300
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        CreatePurchaseLineWithJob(
          PurchaseLine, PurchaseHeader, Item."No.", LibraryRandom.RandIntInRange(10, 20), LibraryRandom.RandIntInRange(300, 400));

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Run "Adjust Cost - Item Entries"
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [THEN] Job consumption entry is posted with fixed cost application
        // [THEN] Unit cost in job consumption is 300
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::"Negative Adjmt.");
        ItemLedgerEntry.FindFirst();
        VerifyItemLedgEntryActualCost(ItemLedgerEntry, -PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity);
        VerifyCostApplication(ItemLedgerEntry."Entry No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure JobConsumptionEntryFixAppliedToPurchaseSNTracking()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // [FEATURE] [Job]
        // [SCENARIO 262595] Job consumption item ledger entry should be posted with fixed application to the purchase entry with item tracking

        Initialize();

        // [GIVEN] Item "I" tracked by serial number
        CreateItem(Item);
        LibraryItemTracking.AddSerialNoTrackingInfo(Item);
        Item.Find();

        // [GIVEN] Purchase 10 pcs of item "I", "Unit Cost" = 100
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", '', '', LibraryRandom.RandIntInRange(10, 20));
        ItemJournalLine.Validate("Unit Amount", LibraryRandom.RandIntInRange(100, 200));
        ItemJournalLine.Modify(true);
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Post a purchase order with linked job for the same item "I", "Unit Cost" = 300
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        CreatePurchaseLineWithJob(
          PurchaseLine, PurchaseHeader, Item."No.", LibraryRandom.RandIntInRange(10, 20), LibraryRandom.RandIntInRange(300, 400));
        PurchaseLine.OpenItemTrackingLines();

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Run "Adjust Cost - Item Entries"
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [THEN] All job consumption entries are posted with fixed cost application
        // [THEN] Unit cost in job consumption is 300
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::"Negative Adjmt.");
        ItemLedgerEntry.FindSet();
        repeat
            VerifyItemLedgEntryActualCost(ItemLedgerEntry, -PurchaseLine."Direct Unit Cost");
            VerifyCostApplication(ItemLedgerEntry."Entry No.");
        until ItemLedgerEntry.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PreciseAvgCostPerEntriesHavingOpenOutboundEntries()
    var
        Item: Record Item;
        PosItemLedgerEntry: Record "Item Ledger Entry";
        NegItemLedgerEntry: Record "Item Ledger Entry";
        ItemCostManagement: Codeunit ItemCostManagement;
        AverageCost: Decimal;
        AverageCostACY: Decimal;
    begin
        // [FEATURE] [Unit Cost] [UT]
        // [SCENARIO 342239] Precise cost calculation of item with open outbound entries in the case of cost equal to amount rounding precision. Using the rounded cost might lead to a big round-off error.
        Initialize();

        LibraryInventory.CreateItem(Item);

        // [GIVEN] Positive item entry. Quantity = 8.003; Unit Cost = 3; Cost Amount = 24.01 (rounded).
        // [GIVEN] Negative item entry. Quantity = -8; Unit Cost = 3; Cost Amount = -24.00.
        // [GIVEN] Another negative item entry resulting in negative inventory. Quantity = -4; Unit Cost = 4; Cost Amount = -16.
        // [GIVEN] The positive entry is fully applied to both negative entries and is closed.
        MockItemLedgerEntry(PosItemLedgerEntry, Item."No.", 8.003, 0, 24.01, 0);

        MockItemLedgerEntry(NegItemLedgerEntry, Item."No.", -8, 0, -24.0, 0);
        MockItemApplicationEntry(NegItemLedgerEntry."Entry No.", PosItemLedgerEntry."Entry No.", NegItemLedgerEntry."Entry No.", -8);

        MockItemLedgerEntry(NegItemLedgerEntry, Item."No.", -4, -3.997, -16.0, 0);
        MockItemApplicationEntry(NegItemLedgerEntry."Entry No.", PosItemLedgerEntry."Entry No.", NegItemLedgerEntry."Entry No.", -0.003);

        // [WHEN] Calculate unit cost of the item.
        ItemCostManagement.SetProperties(true, 0);
        ItemCostManagement.CalculateAverageCost(Item, AverageCost, AverageCostACY);

        // [THEN] The unit cost is nearly equal to 3. So the item entry causing negative inventory does not affect the unit cost.
        Assert.AreNearlyEqual(24.01 / 8.003, AverageCost, LibraryERM.GetUnitAmountRoundingPrecision(), IncorrectAverageCostErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PreciseAvgCostPerEntriesHavingBothOpenInboundAndOutboundEntries()
    var
        Item: Record Item;
        PosItemLedgerEntry: Record "Item Ledger Entry";
        NegItemLedgerEntry: Record "Item Ledger Entry";
        ItemCostManagement: Codeunit ItemCostManagement;
        AverageCost: Decimal;
        AverageCostACY: Decimal;
    begin
        // [FEATURE] [Unit Cost] [UT]
        // [SCENARIO 342239] Precise cost calculation of item with open inbound and outbound entries in the case of cost equal to amount rounding precision. Using the rounded cost might lead to a big round-off error.
        Initialize();

        LibraryInventory.CreateItem(Item);

        // [GIVEN] Positive item entry. Quantity = 8.003; Unit Cost = 3; Cost Amount = 24.01 (rounded).
        // [GIVEN] Negative item entry. Quantity = -8; Unit Cost = 3; Cost Amount = -24.00.
        // [GIVEN] Another negative item entry resulting in negative inventory. Quantity = -4; Unit Cost = 4; Cost Amount = -16.
        // [GIVEN] The positive entry is partially applied to both negative entries and is still open.
        MockItemLedgerEntry(PosItemLedgerEntry, Item."No.", 8.003, 0.001, 24.01, 0);

        MockItemLedgerEntry(NegItemLedgerEntry, Item."No.", -8, 0, -24.0, 0);
        MockItemApplicationEntry(NegItemLedgerEntry."Entry No.", PosItemLedgerEntry."Entry No.", NegItemLedgerEntry."Entry No.", -8);

        MockItemLedgerEntry(NegItemLedgerEntry, Item."No.", -4, -3.998, -16.0, 0);
        MockItemApplicationEntry(NegItemLedgerEntry."Entry No.", PosItemLedgerEntry."Entry No.", NegItemLedgerEntry."Entry No.", -0.002);

        // [WHEN] Calculate unit cost of the item.
        ItemCostManagement.SetProperties(true, 0);
        ItemCostManagement.CalculateAverageCost(Item, AverageCost, AverageCostACY);

        // [THEN] The unit cost is nearly equal to 3. So the item entry causing negative inventory does not affect the unit cost.
        Assert.AreNearlyEqual(24.01 / 8.003, AverageCost, LibraryERM.GetUnitAmountRoundingPrecision(), IncorrectAverageCostErr);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Avg. Cost Calc.");
        // Lazy Setup.
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Avg. Cost Calc.");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        IsInitialized := true;

        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Avg. Cost Calc.");
    end;

    local procedure InvtSetup(AverageCostPeriod: Enum "Average Cost Period Type"; AverageCostCalcType: Enum "Average Cost Calculation Type")
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup.Validate("Average Cost Period", AverageCostPeriod);
        InventorySetup."Average Cost Calc. Type" := AverageCostCalcType;
        InventorySetup."Automatic Cost Posting" := false;
        InventorySetup."Automatic Cost Adjustment" := InventorySetup."Automatic Cost Adjustment"::Never;
        InventorySetup."Expected Cost Posting to G/L" := false;
        InventorySetup.Modify(true);
    end;

    local procedure CreateItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate(Description, 'Description Required DK');
        Item.Validate("Costing Method", Item."Costing Method"::Average);
        Item.Modify(true);
    end;

    local procedure CreatePurchaseLineWithJob(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Qty: Decimal; UnitCost: Decimal)
    var
        Job: Record Job;
        JobTask: Record "Job Task";
    begin
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Qty);
        PurchaseLine.Validate("Job No.", Job."No.");
        PurchaseLine.Validate("Job Task No.", JobTask."Job Task No.");
        PurchaseLine.Validate("Direct Unit Cost", UnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure PostPurch(Item: Record Item; LocationCode: Code[10]; PostingDate: Date; Qty: Decimal; UnitAmt: Decimal)
    var
        ItemJnlLine: Record "Item Journal Line";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
    begin
        ItemJnlLine.Init();
        ItemJnlLine.Validate("Document No.", 'my no');
        ItemJnlLine.Validate("Posting Date", PostingDate);
        ItemJnlLine.Validate("Item No.", Item."No.");
        ItemJnlLine.Validate("Location Code", LocationCode);
        ItemJnlLine.Validate(Quantity, Qty);
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Purchase);
        ItemJnlLine.Validate("Unit Cost", UnitAmt);
        ItemJnlLine.Validate("Unit Amount", UnitAmt);
        ItemJnlPostLine.RunWithCheck(ItemJnlLine);
    end;

    local procedure PostTrans(Item: Record Item; FromLocationCode: Code[10]; ToLocationCode: Code[10]; Qty: Decimal)
    var
        ItemJnlLine: Record "Item Journal Line";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
    begin
        ItemJnlLine.Init();
        ItemJnlLine.Validate("Document No.", 'my no');
        ItemJnlLine.Validate("Posting Date", WorkDate());
        ItemJnlLine.Validate("Item No.", Item."No.");
        ItemJnlLine.Validate("Location Code", FromLocationCode);
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Transfer);
        ItemJnlLine.Validate("New Location Code", ToLocationCode);
        ItemJnlLine.Validate(Quantity, Qty);
        ItemJnlPostLine.RunWithCheck(ItemJnlLine);
    end;

    local procedure PostNegPurch(Item: Record Item; var PurchLine: Record "Purchase Line"; LocationCode: Code[10]; Qty: Decimal)
    var
        PurchHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::Item, Item."No.", Qty);
        PurchLine.Validate("Location Code", LocationCode);
        PurchLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, false);
    end;

    local procedure UndoNegPurch(PurchLine: Record "Purchase Line")
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        UndoPurchRcptLine: Codeunit "Undo Purchase Receipt Line";
    begin
        PurchRcptLine.SetRange("Order No.", PurchLine."Document No.");
        PurchRcptLine.SetRange("Order Line No.", PurchLine."Line No.");
        UndoPurchRcptLine.SetHideDialog(true);
        UndoPurchRcptLine.Run(PurchRcptLine);
    end;

    local procedure CalcAndPostRevaluation(Item: Record Item; PostingDate: Date; UnitCostRevalued: Decimal; var QtyRevalued: Decimal)
    var
        ItemJnlLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        // Do revaluation of Item
        GetItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::Revaluation);
        ItemJnlLine.Init();
        ItemJnlLine."Journal Template Name" := ItemJournalBatch."Journal Template Name";
        ItemJnlLine."Journal Batch Name" := ItemJournalBatch.Name;
        LibraryCosting.CreateRevaluationJnlLines(Item, ItemJnlLine, LibraryUtility.GenerateGUID(), "Inventory Value Calc. Per"::Item, "Inventory Value Calc. Base"::" ", false, false, false, PostingDate);

        // Change Unit Cost
        ItemJnlLine.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJnlLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJnlLine.FindFirst();
        ItemJnlLine.Validate("Unit Cost (Revalued)", UnitCostRevalued);
        ItemJnlLine.Modify();
        QtyRevalued := ItemJnlLine.Quantity;

        // Post Revaluation
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure AdjustCost(Item: Record Item)
    begin
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
    end;

    local procedure PostSaleOrder(Item: Record Item; LocationCode: Code[10]; PostingDate: Date; Qty: Decimal; Ship: Boolean; Invoice: Boolean; DocumentNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        if DocumentNo = '' then
            LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '')
        else
            SalesHeader.Get(SalesHeader."Document Type"::Order, DocumentNo);

        SalesHeader.Status := SalesHeader.Status::Open; // Only Open Sales Orders can be changed
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);

        if DocumentNo = '' then
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", Qty)
        else begin
            SalesLine.SetRange("Document Type", SalesHeader."Document Type");
            SalesLine.SetRange("Document No.", SalesHeader."No.");
            SalesLine.FindFirst();
        end;

        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);

        LibrarySales.PostSalesDocument(SalesHeader, Ship, Invoice);

        exit(SalesHeader."No.");
    end;

    local procedure VerifyExpectedCostunit(itemNo: Code[20]; expectedValue: Decimal; tolerance: Decimal)
    var
        ValueEntry: Record "Value Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetCurrentKey("Item No.");
        ItemLedgerEntry.SetRange("Item No.", itemNo);
        ValueEntry.SetCurrentKey("Item Ledger Entry No.");
        if ItemLedgerEntry.FindSet() then
            repeat
                ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgerEntry."Entry No.");
                ValueEntry.FindFirst();
                Assert.AreNearlyEqual(expectedValue, ValueEntry."Cost per Unit", tolerance, '');
            until ItemLedgerEntry.Next() = 0;
    end;

    local procedure VerifyItemUnitCost(ItemNo: Code[20]; ExpectedUnitCost: Decimal)
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        Assert.AreEqual(ExpectedUnitCost, Item."Unit Cost", 'The Unit Cost is not calculated correctly.');
    end;

    local procedure SelectLocBlue(): Code[10]
    var
        Location: Record Location;
    begin
        Location.SetRange("Use As In-Transit", false);
        Location.SetRange("Bin Mandatory", false);
        Location.SetRange("Directed Put-away and Pick", false);
        Location.SetRange("Require Receive", false);
        Location.SetRange("Require Shipment", false);
        Location.FindFirst();
        exit(Location.Code);
    end;

    local procedure CreateCurrencyWithRoundingPrecision(var Currency: Record Currency)
    begin
        LibraryERM.CreateCurrency(Currency);
        Currency.Validate("Amount Rounding Precision", 1 / Power(10, LibraryRandom.RandInt(5)));
        Currency.Modify(true);
    end;

    local procedure MockItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemNo: Code[20]; Qty: Decimal; RemQty: Decimal; CostAmt: Decimal; CostAmtACY: Decimal)
    begin
        ItemLedgerEntry.Init();
        ItemLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(ItemLedgerEntry, ItemLedgerEntry.FieldNo("Entry No."));
        ItemLedgerEntry."Item No." := ItemNo;
        ItemLedgerEntry.Quantity := Qty;
        ItemLedgerEntry."Remaining Quantity" := RemQty;
        ItemLedgerEntry.Open := ItemLedgerEntry."Remaining Quantity" <> 0;
        ItemLedgerEntry.Positive := ItemLedgerEntry.Quantity > 0;
        ItemLedgerEntry.Insert();

        MockValueEntry(ItemLedgerEntry, CostAmt, CostAmtACY);
    end;

    local procedure MockValueEntry(ItemLedgerEntry: Record "Item Ledger Entry"; CostAmt: Decimal; CostAmtACY: Decimal)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.Init();
        ValueEntry."Entry No." := LibraryUtility.GetNewRecNo(ValueEntry, ValueEntry.FieldNo("Entry No."));
        ValueEntry."Item Ledger Entry No." := ItemLedgerEntry."Entry No.";
        ValueEntry."Item No." := ItemLedgerEntry."Item No.";
        ValueEntry."Item Ledger Entry Quantity" := ItemLedgerEntry.Quantity;
        ValueEntry."Cost Amount (Actual)" := CostAmt;
        ValueEntry."Cost Amount (Actual) (ACY)" := CostAmtACY;
        ValueEntry.Insert();
    end;

    local procedure MockItemApplicationEntry(ItemLedgEntryNo: Integer; InbndItemLedgEntryNo: Integer; OutbndItemLedgEntryNo: Integer; Qty: Decimal)
    var
        ItemApplicationEntry: Record "Item Application Entry";
    begin
        ItemApplicationEntry.Init();
        ItemApplicationEntry."Entry No." := LibraryUtility.GetNewRecNo(ItemApplicationEntry, ItemApplicationEntry.FieldNo("Entry No."));
        ItemApplicationEntry."Item Ledger Entry No." := ItemLedgEntryNo;
        ItemApplicationEntry."Inbound Item Entry No." := InbndItemLedgEntryNo;
        ItemApplicationEntry."Outbound Item Entry No." := OutbndItemLedgEntryNo;
        ItemApplicationEntry.Quantity := Qty;
        ItemApplicationEntry.Insert();
    end;

    local procedure PostPositiveAndNegativeAdjustments(ItemNo: Code[20]; QtyDifference: Decimal; AmtDifference: Decimal; AmtACYDifference: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        PositiveQty: Decimal;
        PositiveAmt: Decimal;
        PositiveAmtACY: Decimal;
        NegativeQty: Decimal;
        NegativeAmt: Decimal;
        NegativeAmtACY: Decimal;
    begin
        PositiveQty := LibraryRandom.RandIntInRange(11, 20);
        PositiveAmt := LibraryRandom.RandDecInRange(50, 100, 2);
        PositiveAmtACY := LibraryRandom.RandDecInRange(50, 100, 2);
        NegativeQty := PositiveQty - QtyDifference;
        NegativeAmt := PositiveAmt - AmtDifference;
        NegativeAmtACY := PositiveAmtACY - AmtACYDifference;

        MockItemLedgerEntry(ItemLedgerEntry, ItemNo, PositiveQty, PositiveQty - NegativeQty, PositiveAmt, PositiveAmtACY);
        MockItemLedgerEntry(ItemLedgerEntry, ItemNo, -NegativeQty, 0, -NegativeAmt, -NegativeAmtACY);
    end;

    local procedure GetItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; TemplateType: Enum "Item Journal Template Type")
    begin
        ItemJournalBatch.SetRange("Template Type", TemplateType);
        if ItemJournalBatch.FindFirst() then begin
            if ItemJournalBatch."No. Series" <> '' then begin
                ItemJournalBatch.Validate("No. Series", '');
                ItemJournalBatch.Modify(true);
            end;
            exit;
        end;

        ItemJournalBatch.Init();
        ItemJournalBatch.Validate("Journal Template Name", GetItemJournalTemplate(TemplateType));
        ItemJournalBatch.Validate(
          Name, CopyStr(LibraryUtility.GenerateRandomCode(ItemJournalBatch.FieldNo(Name), DATABASE::"Item Journal Batch"), 1,
            MaxStrLen(ItemJournalBatch.Name)));
        ItemJournalBatch.Insert(true);
    end;

    local procedure GetItemJournalTemplate(TemplateType: Enum "Item Journal Template Type"): Code[10]
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        ItemJournalTemplate.SetRange(Type, TemplateType);
        if ItemJournalTemplate.FindFirst() then
            exit(ItemJournalTemplate.Name);

        ItemJournalTemplate.Init();
        ItemJournalTemplate.Name :=
          CopyStr(
            LibraryUtility.GenerateRandomCode(ItemJournalTemplate.FieldNo(Name), DATABASE::"Item Journal Template"),
            1,
            LibraryUtility.GetFieldLength(DATABASE::"Item Journal Template", ItemJournalTemplate.FieldNo(Name)));
        ItemJournalTemplate.Type := TemplateType;
        ItemJournalTemplate.Insert();

        exit(ItemJournalTemplate.Name);
    end;

    local procedure UpdateAdditionalReportingCurrencyInGLSetup(var GeneralLedgerSetup: Record "General Ledger Setup"; ACYCode: Code[10]) OldACYCode: Code[10]
    begin
        GeneralLedgerSetup.Get();
        OldACYCode := GeneralLedgerSetup."Additional Reporting Currency";
        GeneralLedgerSetup."Additional Reporting Currency" := ACYCode;
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure CalcOpenItemLedgerEntriesAverageUnitCosts(ItemNo: Code[20]; var AverageCost: Decimal; var AverageCostACY: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        TotalQuantity: Decimal;
    begin
        AverageCost := 0;
        AverageCostACY := 0;

        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange(Positive, true);
        ItemLedgerEntry.SetRange(Open, true);
        ItemLedgerEntry.CalcSums(Quantity);
        TotalQuantity := ItemLedgerEntry.Quantity;

        ItemLedgerEntry.FindSet();
        repeat
            ItemLedgerEntry.CalcFields("Cost Amount (Actual)", "Cost Amount (Actual) (ACY)");
            AverageCost += ItemLedgerEntry."Cost Amount (Actual)";
            AverageCostACY += ItemLedgerEntry."Cost Amount (Actual) (ACY)";
        until ItemLedgerEntry.Next() = 0;

        AverageCost /= TotalQuantity;
        AverageCostACY /= TotalQuantity;
    end;

    local procedure CalcBulkAverageUnitCosts(ItemNo: Code[20]; var AverageCost: Decimal; var AverageCostACY: Decimal)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.CalcSums("Item Ledger Entry Quantity", "Cost Amount (Actual)", "Cost Amount (Actual) (ACY)");
        AverageCost := ValueEntry."Cost Amount (Actual)" / ValueEntry."Item Ledger Entry Quantity";
        AverageCostACY := ValueEntry."Cost Amount (Actual) (ACY)" / ValueEntry."Item Ledger Entry Quantity";
    end;

    local procedure FindPurchRcptLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; OrderNo: Code[20])
    begin
        PurchRcptLine.SetRange("Order No.", OrderNo);
        PurchRcptLine.FindFirst();
    end;

    local procedure FindAvgCostAdjmtEntryPoint(var AvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point"; ItemNo: Code[20])
    begin
        AvgCostAdjmtEntryPoint.SetRange("Item No.", ItemNo);
        AvgCostAdjmtEntryPoint.FindFirst();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure YesConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    local procedure VerifyItemLedgEntryActualCost(var ItemLedgerEntry: Record "Item Ledger Entry"; CostAmt: Decimal)
    begin
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        ItemLedgerEntry.TestField("Cost Amount (Actual)", CostAmt);
    end;

    local procedure VerifyCostApplication(OutboundEntryNo: Integer)
    var
        ItemApplicationEntry: Record "Item Application Entry";
    begin
        ItemApplicationEntry.SetRange("Outbound Item Entry No.", OutboundEntryNo);
        ItemApplicationEntry.FindFirst();
        ItemApplicationEntry.TestField("Cost Application", true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines."Assign Serial No.".Invoke();
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EnterQuantityToCreatePageHandler(var EnterQuantitytoCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantitytoCreate.OK().Invoke();
    end;
}

