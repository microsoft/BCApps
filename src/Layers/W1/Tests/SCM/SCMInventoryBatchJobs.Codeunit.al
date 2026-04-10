codeunit 137285 "SCM Inventory Batch Jobs"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [SCM]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        isInitialized: Boolean;
        FiltersMustNotBeUsedErr: Label 'You must not use Item No. Filter and Item Category Filter at the same time.';
        CostLbl: Label 'Cost';
        FieldValidationErr: Label '%1 must be %2.', Comment = '%1:Field1,%2:Value1';
        UndoShipmentQst: Label 'Do you want to undo the selected shipment line(s)?';
        UndoConsumptionQst: Label 'Do you want to undo consumption of the selected shipment line(s)?';

    [Test]
    [Scope('OnPrem')]
    procedure TFS360566_CalcRevaluationJnlWithInventoryValueZero()
    var
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        ItemNo: Code[20];
    begin
        // [SCENARIO 360566] Revaluation of Item with "Inventory Value Zero" = Yes is not allowed
        Initialize();

        // [GIVEN] Create Item "X" With 'Inventory Value Zero'=Yes
        ItemNo := CreateItemWithInventoryValueZero(true);
        // [GIVEN] Create Revaluation Item Jnl Line
        ItemJnlLine."Value Entry Type" := ItemJnlLine."Value Entry Type"::Revaluation;

        // [WHEN] Set "Item No." to "X" in Revaluation Item Jnl Line
        asserterror ItemJnlLine.Validate("Item No.", ItemNo);

        // [THEN] Error message: "Inventory Value Zero must be equal to No"
        Assert.ExpectedTestFieldError(Item.FieldCaption("Inventory Value Zero"), Format(false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AppliedEntriesUsingAdjustCostItemEntries()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // Verify Item Ledger Entry after running Adjust Cost Item Entries.

        // Setup: Update Sales and Receivables Setup, Ship a Service Order.
        Initialize();
        LibrarySales.SetCreditWarningsToNoWarnings();
        LibrarySales.SetStockoutWarning(false);
        CreateServiceDocumentAndUpdateServiceLine(
          ServiceLine, CreateItem('', Item."Costing Method"::FIFO), CreateCustomer(), LibraryRandom.RandDec(10, 2));  // Use random value for Quantity.
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // Receive a Purchase Order, Receive and Invoice another Purchase Order with different cost.
        CreateAndPostPurchaseDocument(PurchaseLine, ServiceLine."No.", ServiceLine.Quantity, false);  // False for Invoice.
        CreatePurchaseOrder(PurchaseLine2, PurchaseLine."Buy-from Vendor No.", PurchaseLine."No.", PurchaseLine.Quantity);
        PurchaseLine2.Validate("Direct Unit Cost", PurchaseLine."Direct Unit Cost" + 10);  // Fixed value is taken for greater value of Direct unit Cost.
        PurchaseLine2.Modify();
        PostPurchaseDocument(PurchaseLine2, true);

        // Exercise: Run Adjust Cost Item Entries.
        LibraryCosting.AdjustCostItemEntries(PurchaseLine2."No.", '');

        // Verify.
        VerifyItemLedgerEntry(
          ItemJournalLine."Entry Type"::Purchase, PurchaseLine."No.", PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost", 0, 0, false,
          true);
        VerifyItemLedgerEntry(
          ItemJournalLine."Entry Type"::Purchase, PurchaseLine2."No.", 0, PurchaseLine2.Quantity,
          PurchaseLine2.Quantity * PurchaseLine2."Direct Unit Cost", true, false);
        VerifyItemLedgerEntry(
          ItemJournalLine."Entry Type"::Sale, ServiceLine."No.", -PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost", 0, 0, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostInventoryCostToGLWithPostMethodPerEntry()
    var
        PurchaseLine: Record "Purchase Line";
        PostMethod: Option "per Posting Group","per Entry";
    begin
        // Verify Value Entry after running Post Inventory Cost To G/L batch job using Post Method 'Per Entry'.

        // Setup: Update Sales and Receivables Setup, Ship a Service Order, Receive a Purchase Order and Receive and Invoice another Purchase Order.
        Initialize();
        LibrarySales.SetCreditWarningsToNoWarnings();
        LibrarySales.SetStockoutWarning(false);
        CreateServiceAndPurchaseOrder(PurchaseLine);
        PostPurchaseDocument(PurchaseLine, true);

        // Exercise: Run Post Inventory Cost To G/L batch job.
        RunPostInventoryCostToGL(PostMethod::"per Entry", PurchaseLine."No.", '');

        // Verify: Verify Item Ledger Entry after running Adjust Cost Item Entries.
        VerifyValueEntryCost(PurchaseLine."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostInventoryCostToGLWithPerPostingGroup()
    var
        PurchaseLine: Record "Purchase Line";
        PostMethod: Option "per Posting Group","per Entry";
    begin
        // Verify Value Entry after running Post Invt Cost To G/L batch job using Post Method 'Per Posting Group'.

        // Setup: Update Sales and Receivables, Ship a Service Order, Receive a Purchase Order and Receive and Invoice another Purchase Order.
        Initialize();
        LibrarySales.SetCreditWarningsToNoWarnings();
        LibrarySales.SetStockoutWarning(false);
        CreateServiceAndPurchaseOrder(PurchaseLine);
        PostPurchaseDocument(PurchaseLine, true);

        // Exercise: Run Post Inventory Cost To G/L batch job.
        RunPostInventoryCostToGL(PostMethod::"per Posting Group", PurchaseLine."No.", PurchaseLine."No.");

        // Verify: Verify Item Ledger Entry after running Adjust Cost Item Entries.
        VerifyValueEntryCost(PurchaseLine."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostInvtCostToGLTestUsingPostMethodPerEntry()
    var
        PurchaseLine: Record "Purchase Line";
        PostMethod: Option "per Posting Group","per Entry";
    begin
        // Verify Value Entry after running Post Inventory Cost To G/L - Test batch job using Post Method 'Per Entry'.

        // Setup: Update Sales and Receivables Setup, Ship a Service Order, Receive a Purchase Order and Receive and Invoice another Purchase Order.
        Initialize();
        LibrarySales.SetCreditWarningsToNoWarnings();
        LibrarySales.SetStockoutWarning(false);
        CreateServiceAndPurchaseOrder(PurchaseLine);
        PostPurchaseDocument(PurchaseLine, true);

        // Exercise: Run Post Invt. Cost To G/L - Test batch job.
        LibraryCosting.PostInvtCostToGLTest(PostMethod::"per Entry", PurchaseLine."No.", '', false, false);

        // Verify: Verify Item Ledger Entry after running Adjust Cost Item Entries.
        VerifyValueEntryCost(PurchaseLine."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostInvtCostToGLTestUsingPerPostingGroup()
    var
        PurchaseLine: Record "Purchase Line";
        PostMethod: Option "per Posting Group","per Entry";
    begin
        // Verify Value Entry after running Post Inventory Cost To G/L - Test batch job using Post Method 'Per Posting Group'.

        // Setup: Update Sales and Receivables Setup, Ship a Service Order, Receive a Purchase Order and Receive and Invoice another Purchase Order.
        Initialize();
        LibrarySales.SetCreditWarningsToNoWarnings();
        LibrarySales.SetStockoutWarning(false);
        CreateServiceAndPurchaseOrder(PurchaseLine);
        PostPurchaseDocument(PurchaseLine, true);

        // Exercise: Run Post Invt. Cost To G/L - Test batch job.
        LibraryCosting.PostInvtCostToGLTest(PostMethod::"per Posting Group", PurchaseLine."No.", PurchaseLine."No.", false, false);

        // Verify: Verify Item Ledger Entry after running Adjust Cost Item Entries.
        VerifyValueEntryCost(PurchaseLine."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostInventoryCostToGLUsingExpectedCostToGLTrue()
    var
        PurchaseLine: Record "Purchase Line";
        PostMethod: Option "per Posting Group","per Entry";
    begin
        // Verify Warning after running Post Inventory Cost To G/L - Test batch job Using Expected Cost Posting To G/L True.

        // Setup: Update Sales and Receivables Setup, Ship a Service Order, Receive a Purchase Order and Receive and Invoice another Purchase Order.
        Initialize();

        UpdateInventorySetup(false);
        CreateServiceAndPurchaseOrder(PurchaseLine);
        PostPurchaseDocument(PurchaseLine, true);

        // Exercise: Run Post Invt. Cost To G/L - Test batch job.
        RunPostInventoryCostToGL(PostMethod::"per Entry", PurchaseLine."No.", '');

        // Verify: Verify Confirmation Warning and message, Verifyication done in 'ConfirmHandler' and 'MessageHandler'.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdjustCostItemEntriesUsingItemCategoryCode()
    var
        Item: Record Item;
        ItemCategory: Record "Item Category";
        PurchaseLine: Record "Purchase Line";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // Verify Item Category Code on Item Ledger Entry and Value Entry for Average costing after running Adjust Cost Item Entries.

        // Setup: Update Inventory Setup, Ship a Service Order.
        Initialize();

        UpdateInventorySetup(true);
        LibraryInventory.CreateItemCategory(ItemCategory);
        CreateServiceDocumentAndUpdateServiceLine(
          ServiceLine, CreateItem(ItemCategory.Code, Item."Costing Method"::Average), CreateCustomer(), LibraryRandom.RandDec(10, 2));  // Use random value for Quantity.
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        CreateAndPostPurchaseDocument(PurchaseLine, ServiceLine."No.", ServiceLine.Quantity, false);  // False for Invoice.

        // Exercise: Run Adjust Cost Item Entries.
        LibraryCosting.AdjustCostItemEntries('', ItemCategory.Code);

        // Verify: Verify Adjusted Cost Amount in Value Entry.
        VerifyValueByAverageValueEntry(ServiceLine."No.", -PurchaseLine.Quantity, true);  // Using TRUE for Valued By Average Cost.
        VerifyItemCategoryOnItemLedger(ServiceLine."No.", ItemCategory.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorWithItemNoFilterAndItemCategoryFilter()
    var
        Item: Record Item;
        ItemCategory: Record "Item Category";
        PurchaseLine: Record "Purchase Line";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // Verify Error message while running Adjust Cost Item Entries batch job with both Item No. Filter and Item Category Filter.

        // Setup: Update Inventory Setup, Ship a Service Order.
        Initialize();

        UpdateInventorySetup(true);
        LibraryInventory.CreateItemCategory(ItemCategory);
        CreateServiceDocumentAndUpdateServiceLine(
          ServiceLine, CreateItem(ItemCategory.Code, Item."Costing Method"::Average), CreateCustomer(), LibraryRandom.RandDec(10, 2));  // Use random value for Quantity.
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        CreateAndPostPurchaseDocument(PurchaseLine, ServiceLine."No.", ServiceLine.Quantity, false);  // False for Invoice.

        // Exercise: Run Adjust Cost Item Entries.
        asserterror LibraryCosting.AdjustCostItemEntries(ServiceLine."No.", ItemCategory.Code);

        // Verify.
        Assert.ExpectedError(FiltersMustNotBeUsedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VarianceInValueEntryUsingItemWithStandardCost()
    var
        Item: Record Item;
        ItemCategory: Record "Item Category";
        ItemVariant: Record "Item Variant";
        PurchaseLine: Record "Purchase Line";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ValueEntry: Record "Value Entry";
    begin
        // Verify Variant Code and Valued Quantity on Value Entry for Standard costing after running Adjust Cost Item Entries.

        // Setup: Update Inventory Setup, Ship a Service Order and Receive and Invoice a Purchase Order with Variant Code and Standard Item.
        Initialize();

        UpdateInventorySetup(true);
        LibraryInventory.CreateItemCategory(ItemCategory);
        CreateServiceDocumentAndUpdateServiceLine(
          ServiceLine, CreateItem(ItemCategory.Code, Item."Costing Method"::Standard), CreateCustomer(), LibraryRandom.RandDec(10, 2));  // Use random value for Quantity.
        ServiceLine.Validate("Variant Code", LibraryInventory.CreateItemVariant(ItemVariant, ServiceLine."No."));
        ServiceLine.Modify(true);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        CreatePurchaseOrder(PurchaseLine, CreateVendor(), ServiceLine."No.", ServiceLine.Quantity);
        PurchaseLine.Validate("Variant Code", ServiceLine."Variant Code");
        PurchaseLine.Modify(true);
        PostPurchaseDocument(PurchaseLine, true);

        // Exercise: Run Adjust Cost Item Entries.
        LibraryCosting.AdjustCostItemEntries('', ItemCategory.Code);

        // Verify: Verify Variant Code for Variance from Value Entry.
        FindValueEntry(
          ValueEntry, ValueEntry."Item Ledger Entry Type"::Purchase, ValueEntry."Entry Type"::Variance, ServiceLine."No.", false, '');
        ValueEntry.TestField("Variant Code", PurchaseLine."Variant Code");
        ValueEntry.TestField("Valued Quantity", PurchaseLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdjustCostItemEntriesUsingAverageCost()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ValueEntry: Record "Value Entry";
        DocumentNo: Code[20];
        ItemChargeNo: Code[20];
    begin
        // Verify Chage Item, Adjustment and Valued By Average Cost field in Value Entry after running Adjust Cost Item Entries.

        // Setup: Ship a Service Order and Receive a Purchase Order and Post Purchase Invoice using Item Charge Assignment.
        Initialize();
        CreateServiceDocumentAndUpdateServiceLine(
          ServiceLine, CreateItem('', Item."Costing Method"::Average), CreateCustomer(), LibraryRandom.RandDec(10, 2));  // Use random value for Quantity.
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        CreatePurchaseOrder(PurchaseLine, CreateVendor(), ServiceLine."No.", LibraryRandom.RandDec(10, 2));  // Use Random value for Quantity.
        PostPurchaseDocument(PurchaseLine, false);

        // Post Charge Item.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        ItemChargeNo := LibraryInventory.CreateItemChargeNo();
        DocumentNo :=
          CreateAndPostChargeItemPurchaseDocument(
            PurchaseLine2, PurchaseHeader."Buy-from Vendor No.", PurchaseHeader."No.", PurchaseLine."No.",
            ItemChargeNo);

        // Exercise: Run Adjust Cost Item Entries.
        LibraryCosting.AdjustCostItemEntries(PurchaseLine."No.", '');

        // Verify: Verify Adjustment entry for Valued By Average Cost Item Charge in  Value Entry.
        ValueEntry.SetRange("Document No.", DocumentNo);
        ValueEntry.SetRange("Item Charge No.", ItemChargeNo);
        ValueEntry.FindFirst();
        ValueEntry.TestField("Valued Quantity", PurchaseLine.Quantity);
        VerifyValueByAverageValueEntry(PurchaseLine."No.", -ServiceLine.Quantity, true);  // Using TRUE for Valued By Average Cost.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdjustAppliedFromEntries()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        ValueEntry: Record "Value Entry";
        CostPerUnit: Decimal;
    begin
        // Verify Value Entry for applied and Invoiced Sales Order after running Adjust Cost Item Entries.

        // Setup: Create and Post Purchase Order. Create, apply and Post Sales Order. Create and Post Purchase Invoice for Charge Item.
        Initialize();
        CreateAndPostPurchaseDocument(PurchaseLine, CreateItem('', Item."Costing Method"::FIFO), LibraryRandom.RandDec(10, 2), true);  // True for Invoice and Random value for Quantity.
        FindItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Purchase, PurchaseLine."No.", true);
        CreateAndPostSalesDocument(SalesLine, PurchaseLine."No.", PurchaseLine.Quantity, ItemLedgerEntry."Entry No.", true);
        CreateAndPostChargeItemPurchaseDocument(
          PurchaseLine2, PurchaseLine."Buy-from Vendor No.", PurchaseLine."Document No.", PurchaseLine."No.",
          LibraryInventory.CreateItemChargeNo());
        CostPerUnit := PurchaseLine2."Line Amount" / PurchaseLine.Quantity;

        // Exercise: Run Adjust Cost Item Entries.
        LibraryCosting.AdjustCostItemEntries(PurchaseLine."No.", '');  // Blank value for Item Category.

        // Verify: Verify Cost Amount Actual on Value Entry.
        VerifyCostAmountActual(
          ValueEntry, ValueEntry."Item Ledger Entry Type"::Sale, ValueEntry."Entry Type"::"Direct Cost", PurchaseLine."No.", true, '',
          -Round(SalesLine.Quantity * CostPerUnit));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdjustmentOfInvoicedAndExpectedNegativeEntries()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        ValueEntry: Record "Value Entry";
    begin
        // Verify Value Entry for applied but not Invoiced Sales Order.

        // Setup: Create and post Purchase Order.
        Initialize();
        CreateAndPostPurchaseDocument(PurchaseLine, CreateItem('', Item."Costing Method"::FIFO), LibraryRandom.RandDec(10, 2), true);  // True for Invoice and Random value for Quantity.
        FindItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Purchase, PurchaseLine."No.", true);

        // Exercise: Create, apply and Ship Sales Order.
        CreateAndPostSalesDocument(SalesLine, PurchaseLine."No.", PurchaseLine.Quantity, ItemLedgerEntry."Entry No.", false);

        // Verify: Verify Cost Amount Expected on Value Entry.
        FindValueEntry(
          ValueEntry, ValueEntry."Item Ledger Entry Type"::Sale, ValueEntry."Entry Type"::"Direct Cost", PurchaseLine."No.", false, '');
        ValueEntry.TestField("Expected Cost", true);
        ValueEntry.TestField("Cost Amount (Expected)", -Round(PurchaseLine."Direct Unit Cost" * SalesLine.Quantity));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdjustmentForRevaluation()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        ValueEntry: Record "Value Entry";
        CostPerUnit: Decimal;
    begin
        // Verify Value Entry after posting Revaluation Journal and running Adjust Cost Item Entries.

        // Setup: Create and Post Purchase Order. Create, apply and Post Sales Order. Create and Post Revaluation Journal.
        Initialize();
        CreateAndPostPurchaseDocument(
          PurchaseLine, CreateItem('', Item."Costing Method"::FIFO), 10 + LibraryRandom.RandDec(10, 2), true);  // True for Invoice and Random value for Quantity.
        FindItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Purchase, PurchaseLine."No.", true);
        CreateAndPostSalesDocument(SalesLine, PurchaseLine."No.", LibraryRandom.RandDec(10, 2), ItemLedgerEntry."Entry No.", true);  // Use Random value for Quantity.
        CostPerUnit :=
          CreateAndPostRevaluationJournal(PurchaseLine."No.", ItemLedgerEntry."Entry No.", LibraryRandom.RandDec(100, 2), 0);  // Use Random value for Inventory Value Revalued and 0 for Unit Cost Revalued.

        // Exercise: Run Adjust Cost Item Entries.
        LibraryCosting.AdjustCostItemEntries(PurchaseLine."No.", '');  // Blank value for Item Category.

        // Verify: Verify Cost Amount Actual on Value Entry.
        VerifyCostAmountActual(
          ValueEntry, ValueEntry."Item Ledger Entry Type"::Sale, ValueEntry."Entry Type"::"Direct Cost", PurchaseLine."No.", true, '',
          -Round(SalesLine.Quantity * CostPerUnit));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdjustmentForPartialRevaluation()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        SalesLine: Record "Sales Line";
        ValueEntry: Record "Value Entry";
        CostPerUnit: Decimal;
        CostAmountActual: Decimal;
        CostAmountActual2: Decimal;
        UnitCost: Decimal;
    begin
        // Verify Value Entry after posting Revaluation Journal for remaining Quantity and running Adjust Cost Item Entries.

        // Setup: Create and Post Item Journal for Positive Adjustment. Create, apply and Post Negative Adjustment. Create and Post Revaluation Journal. Use Random values for Quantity and Unit Cost.
        Initialize();
        UnitCost := LibraryRandom.RandDec(100, 2);

        // Create and Post Item Journal Line for Positive/Negative Adjustment.
        CreateAndPostItemJournal(
          ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", CreateItem('', Item."Costing Method"::FIFO),
          2 * LibraryRandom.RandDec(10, 2), '', UnitCost, 0);
        FindItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::"Positive Adjmt.", ItemJournalLine."Item No.", true);
        CreateAndPostItemJournal(
          ItemJournalLine, ItemJournalLine."Entry Type"::"Negative Adjmt.", ItemJournalLine."Item No.", ItemJournalLine.Quantity / 2, '',
          Item."Last Direct Cost", ItemLedgerEntry."Entry No.");
        CreateItemJournalForRevaluation(ItemJournalLine."Item No.");

        // Post Sales Document for Same Item and Quantiity and Apply  with Previous posted entries.
        CreateAndPostSalesDocument(SalesLine, ItemJournalLine."Item No.", ItemJournalLine.Quantity, ItemLedgerEntry."Entry No.", true);
        FindItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::"Positive Adjmt.", ItemJournalLine."Item No.", false);
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        CostPerUnit := ItemLedgerEntry."Cost Amount (Actual)" / ItemLedgerEntry.Quantity;
        CostAmountActual := -Round(SalesLine.Quantity * CostPerUnit);
        Item.Get(ItemJournalLine."Item No.");
        CostAmountActual2 := -Round(SalesLine.Quantity * (CostPerUnit - UnitCost));

        // Exercise: Run Adjust Cost Item Entries.
        LibraryCosting.AdjustCostItemEntries(ItemJournalLine."Item No.", '');  // Blank value for Item Category.

        // Verify: Verify Cost Amount Actual on Value Entries.
        FindValueEntry(
          ValueEntry, ValueEntry."Item Ledger Entry Type"::Sale, ValueEntry."Entry Type"::"Direct Cost", ItemJournalLine."Item No.", false,
          '');
        Assert.AreNearlyEqual(
          CostAmountActual, ValueEntry."Cost Amount (Actual)", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(FieldValidationErr, ItemLedgerEntry.FieldCaption("Cost Amount (Actual)"), CostAmountActual));
        FindValueEntry(
          ValueEntry, ValueEntry."Item Ledger Entry Type"::Sale, ValueEntry."Entry Type"::"Direct Cost", ItemJournalLine."Item No.", true,
          '');
        Assert.AreNearlyEqual(
          CostAmountActual2, ValueEntry."Cost Amount (Actual)", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(FieldValidationErr, ItemLedgerEntry.FieldCaption("Cost Amount (Actual)"), CostAmountActual2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InsertionOfRoundingEntries()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchaseLine: Record "Purchase Line";
        ValueEntry: Record "Value Entry";
        CostAmountForRounding: Decimal;
    begin
        // Verify Value Entry for Rounding after running Adjust Cost Item Entries.

        // Setup: Create and Post Purchase Order. Create, apply and Post Sales Order.
        Initialize();
        CreateAndPostPurchaseOrderWithLineAmount(PurchaseLine);
        FindItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Purchase, PurchaseLine."No.", true);
        CreateAndPostSalesOrderWithMultiLine(PurchaseLine."No.", PurchaseLine.Quantity, ItemLedgerEntry."Entry No.");
        CostAmountForRounding :=
          PurchaseLine."Line Amount" - (PurchaseLine.Quantity * Round(PurchaseLine."Line Amount" / PurchaseLine.Quantity));

        // Exercise: Run Adjust Cost Item Entries.
        LibraryCosting.AdjustCostItemEntries(PurchaseLine."No.", '');  // Blank value for Item Category.

        // Verify: Verify Cost Amount Actual on Value Entry.
        VerifyCostAmountActual(
          ValueEntry, ValueEntry."Item Ledger Entry Type"::Purchase, ValueEntry."Entry Type"::Rounding, PurchaseLine."No.", false, '',
          -CostAmountForRounding);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdjustmentWithQuantityShippedNotApplied()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        ValueEntry: Record "Value Entry";
    begin
        // Verify Value Entry for unapplied Invoiced Sales Order after running Adjust Cost Item Entries.

        // Setup: Create and Post Purchase Order. Create and Post Sales Order. Create and post Purchase Invoice for Charge Item.
        Initialize();
        CreateAndPostPurchaseDocument(
          PurchaseLine, CreateItem('', Item."Costing Method"::FIFO), 10 + LibraryRandom.RandDec(10, 2), true);  // True for Invoice and Random value for Quantity.
        FindItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Purchase, PurchaseLine."No.", true);
        CreateAndPostSalesDocument(SalesLine, PurchaseLine."No.", PurchaseLine.Quantity, 0, true);
        CreateAndPostChargeItemPurchaseDocument(
          PurchaseLine2, PurchaseLine."Buy-from Vendor No.", PurchaseLine."Document No.", PurchaseLine."No.",
          LibraryInventory.CreateItemChargeNo());

        // Exercise: Run Adjust Cost Item Entries.
        LibraryCosting.AdjustCostItemEntries(PurchaseLine."No.", '');  // Blank value for Item Category.

        // Verify: Verify Cost Amount Actual on Value Entries.
        VerifyCostAmountActual(
          ValueEntry, ValueEntry."Item Ledger Entry Type"::Sale, ValueEntry."Entry Type"::"Direct Cost", PurchaseLine."No.", false, '',
          -Round(SalesLine.Quantity * PurchaseLine."Direct Unit Cost"));
        VerifyCostAmountActual(
          ValueEntry, ValueEntry."Item Ledger Entry Type"::Sale, ValueEntry."Entry Type"::"Direct Cost", PurchaseLine."No.", true, '',
          -PurchaseLine2."Direct Unit Cost");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdjustTransferredFromEntries()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Location: Record Location;
        TransferHeader: Record "Transfer Header";
        ValueEntry: Record "Value Entry";
        CostPerUnit: Decimal;
        UnitCost: Decimal;
        CostAmountActual: Decimal;
    begin
        // Verify Value Entry after creating Transfer Order,posting Revaluation Journal and running Adjust Cost Item Entries.

        // Setup: Create and Post Item Journal for Positive Adjustment. Create and Post Transfer Order. Create and Post Revaluation Journal. Use Random values for Quantity and Unit Cost.
        Initialize();
        UnitCost := LibraryRandom.RandDec(100, 2);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        CreateAndPostItemJournal(
          ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", CreateItem('', Item."Costing Method"::FIFO),
          LibraryRandom.RandDec(10, 2), Location.Code, UnitCost, 0);
        FindItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::"Positive Adjmt.", ItemJournalLine."Item No.", true);
        CreateAndPostTransferOrder(TransferHeader, ItemJournalLine."Item No.", Location.Code, ItemJournalLine.Quantity);
        CostPerUnit :=
          CreateAndPostRevaluationJournal(
            ItemJournalLine."Item No.", ItemLedgerEntry."Entry No.", 0, UnitCost + LibraryRandom.RandDec(100, 2));  // Use 0 for Inventory Value Revalued and Random value for Unit Cost Revalued.
        CostAmountActual := ItemJournalLine.Quantity * CostPerUnit;

        // Exercise: Run Adjust Cost Item Entries.
        LibraryCosting.AdjustCostItemEntries(ItemJournalLine."Item No.", '');  // Blank value for Item Category.

        // Verify: Verify Cost Amount Actual on Value Entries for Transfer Receipt.
        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Transfer Receipt");
        VerifyCostAmountActual(
          ValueEntry, ValueEntry."Item Ledger Entry Type"::Transfer, ValueEntry."Entry Type"::"Direct Cost", ItemJournalLine."Item No.",
          true, TransferHeader."Transfer-to Code", CostAmountActual);
        FindValueEntry(
          ValueEntry, ValueEntry."Item Ledger Entry Type"::Transfer, ValueEntry."Entry Type"::"Direct Cost", ItemJournalLine."Item No.",
          true, TransferHeader."In-Transit Code");
        Assert.AreNearlyEqual(
          -ItemJournalLine.Quantity * CostPerUnit, ValueEntry."Cost Amount (Actual)", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(FieldValidationErr, ValueEntry.FieldCaption("Cost Amount (Actual)"), CostAmountActual));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdjustFixedApplications()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemLedgerEntry2: Record "Item Ledger Entry";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        ValueEntry: Record "Value Entry";
    begin
        // Verify Value Entry for fixed application after running Adjust Cost Item Entries.

        // Setup: Create and Post Purchase Order. Create, apply and Post Sales Order and Sales Return Order. Create and Post Purchase Invoice for Charge Item.
        Initialize();
        CreateAndPostPurchaseDocument(PurchaseLine, CreateItem('', Item."Costing Method"::FIFO), LibraryRandom.RandDec(10, 2), true);  // True for Invoice and Random value for Quantity.
        FindItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Purchase, PurchaseLine."No.", true);
        CreateAndPostSalesDocument(SalesLine, PurchaseLine."No.", PurchaseLine.Quantity, ItemLedgerEntry."Entry No.", true);
        FindItemLedgerEntry(ItemLedgerEntry2, ItemLedgerEntry."Entry Type"::Sale, PurchaseLine."No.", false);
        CreateAndPostSalesReturnOrder(SalesLine, PurchaseLine."No.", PurchaseLine.Quantity, ItemLedgerEntry2."Entry No.");
        CreateAndPostChargeItemPurchaseDocument(
          PurchaseLine2, PurchaseLine."Buy-from Vendor No.", PurchaseLine."Document No.", PurchaseLine."No.",
          LibraryInventory.CreateItemChargeNo());

        // Exercise: Run Adjust Cost Item Entries.
        LibraryCosting.AdjustCostItemEntries(PurchaseLine."No.", '');  // Blank value for Item Category.

        // Verify: Verify Cost Amount Actual on Value Entries.
        VerifyCostAmountActual(
          ValueEntry, ValueEntry."Item Ledger Entry Type"::Sale, ValueEntry."Entry Type"::"Direct Cost", PurchaseLine."No.", true, '',
          -PurchaseLine2."Direct Unit Cost");
        VerifyValueEntryForItemCharge(PurchaseLine."No.", PurchaseLine2."No.", PurchaseLine2."Direct Unit Cost");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitCostUsingCalcInvDisc()
    begin
        // Check the Item cost when CalcInvDiscount is true and InventoryValueZero is false.
        Initialize();
        AdjustCostItemEntries(true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitCostUsingCalcInvDiscAndSetInvValueZero()
    begin
        // Check the Item cost when CalcInvDiscount is true and InventoryValueZero is true.
        Initialize();
        AdjustCostItemEntries(true, false);
        AdjustCostItemEntries(true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitCostUsingSetInvValueZero()
    begin
        // Check the Item cost when CalcInvDiscount is false and InventoryValueZero is true.
        Initialize();
        AdjustCostItemEntries(true, true);
        AdjustCostItemEntries(false, true);
    end;

    local procedure AdjustCostItemEntries(CalcInvDiscount: Boolean; InventoryValueZero: Boolean)
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvLine: Record "Purch. Inv. Line";
        DocumentNo: Code[20];
    begin
        // Setup: Update Purchases and Payables Setup, create and post Purchase Order.
        LibraryPurchase.SetCalcInvDiscount(CalcInvDiscount);
        CreatePurchaseOrderAndModifyLine(PurchaseLine, InventoryValueZero);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        PurchInvLine.SetRange("Document No.", DocumentNo);
        PurchInvLine.FindFirst();

        // Exercise: Run Adjust Cost Item Entries.
        LibraryCosting.AdjustCostItemEntries(PurchaseLine."No.", '');

        // Verify: Verify Unit Cost on Item after Adjustment.
        Item.Get(PurchaseLine."No.");
        if Item."Inventory Value Zero" then
            Item.TestField("Unit Cost", 0)
        else
            Item.TestField("Unit Cost", PurchInvLine."Unit Cost");
        Item.TestField("Cost is Adjusted", true);
    end;

#if not CLEAN27
    [Test]
    [HandlerFunctions('PostedServiceInvoiceStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure PstdServInvStatisticsUsingServOrder()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // Verify Original Cost and Adjusted Cost on posted Services Invoice Statistics after posting Service Order.

        // Setup: Create Item, create and post Purchase Order, create Service Order.
        Initialize();
        CreatePurchaseOrder(
          PurchaseLine, CreateVendor(), CreateItem('', Item."Costing Method"::Standard), LibraryRandom.RandDec(10, 2));  // Use Random value for Quantity.
        PostPurchaseDocument(PurchaseLine, true);
        CreateServiceDocumentAndUpdateServiceLine(ServiceLine, PurchaseLine."No.", CreateCustomer(), LibraryRandom.RandDec(10, 2));  // Use random value for Quantity.
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");

        // Exercise: Post Service Order as ship and invoice.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // Verify: Verify Original Cost and Adjusted Cost on posted Services Invoice Statistics.
        VerifyCostOnPostedServiceInvoiceStatistics(
          ServiceLine."Document No.", '',
          GetItemCostLCY(PurchaseLine."No.", PurchaseLine."Currency Code", PurchaseLine.GetDate()) * ServiceLine.Quantity,
          GetItemCostLCY(PurchaseLine."No.", PurchaseLine."Currency Code", PurchaseLine.GetDate()) * ServiceLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('PostedServiceInvoiceStatisticsPageHandler')]
    procedure PstdServInvStatisticsWithRevAndAdjmt()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        UnitCostRevalued: Decimal;
    begin
        // Verify Original Cost and Adjusted Cost on posted Services Invoice Statistics after posting Revaluation Journal and running Adjust Cost Item Entries.

        // Setup: Create Item, create and post Purchase Order, Service Order and Revaluation Journal.
        CreatePurchaseOrder(
          PurchaseLine, CreateVendor(), CreateItem('', Item."Costing Method"::Standard), LibraryRandom.RandDec(10, 2));  // Use Random value for Quantity.
        PostPurchaseDocument(PurchaseLine, true);
        CreateServiceDocumentAndUpdateServiceLine(ServiceLine, PurchaseLine."No.", CreateCustomer(), PurchaseLine.Quantity / 2);  // Take Partial Quantity.
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        FindItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Purchase, PurchaseLine."No.", true);
        UnitCostRevalued :=
            GetItemCostLCY(PurchaseLine."No.", PurchaseLine."Currency Code", PurchaseLine.GetDate()) + LibraryRandom.RandDec(10, 2);  // Add random value to Unit Cost to make positive Revaluation.
        CreateAndPostRevaluationJournal(
          PurchaseLine."No.", ItemLedgerEntry."Entry No.", LibraryRandom.RandDec(100, 2), UnitCostRevalued);  // Use Random value for Inventory Value Revalued and 0 for Unit Cost Revalued.

        // Exercise: Run Adjust Cost Item Entries.
        LibraryCosting.AdjustCostItemEntries(PurchaseLine."No.", '');  // Blank value for Item Category.

        // Verify: Verify Original Cost and Adjusted Cost on posted Services Invoice Statistics.
        VerifyCostOnPostedServiceInvoiceStatistics(
            ServiceLine."Document No.", '',
            GetItemCostLCY(PurchaseLine."No.", PurchaseLine."Currency Code", PurchaseLine.GetDate()) * ServiceLine.Quantity,
            UnitCostRevalued * ServiceLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('PostedServiceCreditMemoStatisticsPageHandler')]
    procedure PstdServCrMemoStatisticsWithAdjmt()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        ServiceLine: Record "Service Line";
    begin
        // Verify Original Cost and Adjusted Cost on posted Services Credit Memo Statistics after posting Service Credit Memo and running Adjust Cost Item Entries.

        // Setup: Create Item, create and post Purchase Order, Service Credit Memo.
        Initialize();
        CreatePurchaseOrder(
          PurchaseLine, CreateVendor(), CreateItem('', Item."Costing Method"::Standard), LibraryRandom.RandDec(10, 2));  // Use Random value for Quantity.
        PostPurchaseDocument(PurchaseLine, true);
        CreateAndPostServiceCreditMemo(ServiceLine, PurchaseLine."No.", LibrarySales.CreateCustomerNo());

        // Exercise: Run Adjust Cost Item Entries.
        LibraryCosting.AdjustCostItemEntries(PurchaseLine."No.", '');  // Blank value for Item Category.

        // Verify: Verify Original Cost and Adjusted Cost on posted Services Invoice Statistics.
        VerifyCostOnPostedServiceCreditMemoStatistics(
          ServiceLine."Document No.", GetItemCostLCY(PurchaseLine."No.", PurchaseLine."Currency Code", PurchaseLine.GetDate()) * ServiceLine.Quantity,
          GetItemCostLCY(PurchaseLine."No.", PurchaseLine."Currency Code", PurchaseLine.GetDate()) * ServiceLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('PostedServiceInvoiceStatisticsPageHandler')]
    procedure PstdServInvStatisticsUsingServOrderWithLineDisc()
    var
        PurchaseLine: Record "Purchase Line";
        ServiceLine: Record "Service Line";
        SalesLineDiscount: Record "Sales Line Discount";
    begin
        // Verify Original Cost and Adjusted Cost on posted Services Invoice Statistics after posting Service Order When Line Discount is defined for Item.

        // Setup: Create Item with Sales Line Discount, create and post Purchase Order, create Service Order.
        Initialize();
        CreateItemWithSalesLineDiscount(SalesLineDiscount);
        CreateAndPostPurchaseDocument(PurchaseLine, SalesLineDiscount.Code, LibraryRandom.RandDec(10, 2), true);  // Use TRUE for Invoice and Random value for Quantity.
        CreateServiceDocumentAndUpdateServiceLine(
          ServiceLine, SalesLineDiscount.Code, SalesLineDiscount."Sales Code", LibraryRandom.RandDec(10, 2));  // Use random value for Quantity.

        // Exercise: Post Service Order as ship and invoice.
        PostServiceOrder(ServiceLine, true, false);

        // Verify: Verify Original Cost and Adjusted Cost on posted Services Invoice Statistics.
        VerifyCostOnPostedServiceInvoiceStatistics(
          ServiceLine."Document No.", '', GetItemCostLCY(PurchaseLine."No.", PurchaseLine."Currency Code", PurchaseLine.GetDate()) * ServiceLine.Quantity,
          GetItemCostLCY(PurchaseLine."No.", PurchaseLine."Currency Code", PurchaseLine.GetDate()) * ServiceLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('PostedServiceInvoiceStatisticsPageHandler')]
    procedure PstdServInvStatisticsWithRevAndWithoutAdjmt()
    var
        PurchaseLine: Record "Purchase Line";
        ServiceLine: Record "Service Line";
        SalesLineDiscount: Record "Sales Line Discount";
    begin
        // Verify Original Cost and Adjusted Cost on posted Services Invoice Statistics after posting Revaluation Journal When Line Discount is defined for Item.

        // Setup: Create Item with Sales Line Discount, create and post Purchase Order, Service Order and Revaluation Journal.
        Initialize();
        CreateItemWithSalesLineDiscount(SalesLineDiscount);
        CreateAndPostPurchaseDocument(PurchaseLine, SalesLineDiscount.Code, LibraryRandom.RandDec(10, 2), true);  // Use TRUE for Invoice and Random value for Quantity.
        CreateServiceDocumentAndUpdateServiceLine(
          ServiceLine, SalesLineDiscount.Code, SalesLineDiscount."Sales Code", PurchaseLine.Quantity - 1);  // Take less Quantity than Purchase Line.
        PostServiceOrder(ServiceLine, true, false);

        // Exercise: Create and post Revaluation Journal.
        CreateItemJournalForRevaluation(SalesLineDiscount.Code);

        // Verify: Verify Original Cost and Adjusted Cost on posted Services Invoice Statistics.
        VerifyCostOnPostedServiceInvoiceStatistics(
          ServiceLine."Document No.", '',
          GetItemCostLCY(PurchaseLine."No.", PurchaseLine."Currency Code", PurchaseLine.GetDate()) * ServiceLine.Quantity,
          GetItemCostLCY(PurchaseLine."No.", PurchaseLine."Currency Code", PurchaseLine.GetDate()) * ServiceLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('PostedServiceCreditMemoStatisticsPageHandler')]
    procedure PstdServCrMemoStatisticsWithoutAdjmt()
    var
        PurchaseLine: Record "Purchase Line";
        ServiceLine: Record "Service Line";
        SalesLineDiscount: Record "Sales Line Discount";
    begin
        // Verify Original Cost and Adjusted Cost on posted Services Credit Memo Statistics after posting Service Credit Memo When Line Discount is defined for Item..

        // Setup: Create Item with Sales Line Discount, create and post Purchase Order, Service Credit Memo.
        Initialize();
        CreateItemWithSalesLineDiscount(SalesLineDiscount);
        CreateAndPostPurchaseDocument(PurchaseLine, SalesLineDiscount.Code, LibraryRandom.RandDec(10, 2), true);  // Use TRUE for Invoice and Random value for Quantity.

        // Exercise: Create and post Service Credit Memo.
        CreateAndPostServiceCreditMemo(ServiceLine, SalesLineDiscount.Code, SalesLineDiscount."Sales Code");

        // Verify: Verify Original Cost and Adjusted Cost on posted Services Invoice Statistics.
        VerifyCostOnPostedServiceCreditMemoStatistics(
          ServiceLine."Document No.", GetItemCostLCY(PurchaseLine."No.", PurchaseLine."Currency Code", PurchaseLine.GetDate()) * ServiceLine.Quantity,
          GetItemCostLCY(PurchaseLine."No.", PurchaseLine."Currency Code", PurchaseLine.GetDate()) * ServiceLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ServiceOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure ServOrderStatisticsPostingServOrderAsShip()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        ServiceLine: Record "Service Line";
    begin
        // Verify Original Cost and Adjusted Cost on Services Order Statistics after posting Service Order as Ship.

        // Setup: Create Item, create and post Purchase Order, Create Service Order.
        Initialize();
        CreateAndPostPurchaseDocument(PurchaseLine, CreateItem('', Item."Costing Method"::FIFO), LibraryRandom.RandDec(10, 2), true);  // Use TRUE for Invoice and Random value for Quantity.
        CreateServiceDocumentAndUpdateServiceLine(ServiceLine, PurchaseLine."No.", CreateCustomer(), LibraryRandom.RandDec(10, 2));  // Use Random value for Quantity.

        // Exercise: Post Service Order as ship.
        PostServiceOrder(ServiceLine, false, false);

        // Verify: Verify Original Cost and Adjusted Cost on Services Order Statistics.
        VerifyServiceOrderStatistics(
          ServiceLine."Document No.", GetItemCost(PurchaseLine."No.") * ServiceLine.Quantity,
          GetItemCostLCY(PurchaseLine."No.", PurchaseLine."Currency Code", PurchaseLine.GetDate()) * ServiceLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ServiceOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure ServOrderStatisticsPostingServOrderAsShipWithAdjmt()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        ServiceLine: Record "Service Line";
        DirectUnitCost: Decimal;
        AdjustedCost: Decimal;
    begin
        // Verify Original Cost and Adjusted Cost on Services Order Statistics after posting Service Order as Ship and running Adjust Cost Item Entries.

        // Setup: Create Item, create and post Purchase Order, Service Order.
        Initialize();
        CreatePurchaseOrder(PurchaseLine, CreateVendor(), CreateItem('', Item."Costing Method"::FIFO), LibraryRandom.RandDec(10, 2));  // Use Random value for Quantity.
        DirectUnitCost := PurchaseLine."Direct Unit Cost";
        PostPartialPurchLineWithUpdate(PurchaseLine);
        AdjustedCost :=
          PurchaseLine."Quantity Invoiced" * DirectUnitCost + PurchaseLine."Qty. to Invoice" * PurchaseLine."Direct Unit Cost";
        PostPurchaseDocument(PurchaseLine, true);
        CreateServiceDocumentAndUpdateServiceLine(ServiceLine, PurchaseLine."No.", CreateCustomer(), PurchaseLine.Quantity);
        PostServiceOrder(ServiceLine, false, false);

        // Exercise: Run Adjust Cost Item Entries.
        LibraryCosting.AdjustCostItemEntries(PurchaseLine."No.", '');  // Blank value for Item Category.

        // Verify: Verify Original Cost and Adjusted Cost on Services Order Statistics.
        VerifyServiceOrderStatistics(ServiceLine."Document No.", DirectUnitCost * ServiceLine.Quantity, AdjustedCost);
    end;

    [Test]
    [HandlerFunctions('ShipmentLinePageHandler,PostedServiceInvoiceStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure PstdServInvStatisticsUsingGetShipmentLines()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        ServiceLine: Record "Service Line";
        OrderNo: Text[20];
    begin
        // Verify Original Cost and Adjusted Cost on posted Services Invoice Statistics after posting Service Order using Get Service Shipment Lines.

        // Setup: Create Item, create and post Purchase Order, create Service Invoice using Get Shipment Lines.
        Initialize();
        CreateAndPostPurchaseDocument(PurchaseLine, CreateItem('', Item."Costing Method"::FIFO), LibraryRandom.RandDec(10, 2), true);  // Use TRUE for Invoice and Random value for Quantity.
        CreateServiceDocumentAndUpdateServiceLine(ServiceLine, PurchaseLine."No.", CreateCustomer(), LibraryRandom.RandDec(10, 2));  // Use Random value for Quantity.
        OrderNo := ServiceLine."Document No.";
        PostServiceOrder(ServiceLine, false, false);
        LibraryVariableStorage.Enqueue(ServiceLine."Document No.");  // Enqueue value for 'ShipmentLinePageHandler'.
        CreateServiceInvoiceFromGetShipmentLines(ServiceLine, ServiceLine."Customer No.");

        // Exercise: Post Service Invoice.
        PostServiceOrder(ServiceLine, true, false);

        // Verify: Verify Original Cost and Adjusted Cost on posted Services Invoice Statistics.
        VerifyCostOnPostedServiceInvoiceStatistics(
          OrderNo, ServiceLine."Document No.", GetItemCostLCY(PurchaseLine."No.", PurchaseLine."Currency Code", PurchaseLine.GetDate()) * ServiceLine.Quantity,
          GetItemCostLCY(PurchaseLine."No.", PurchaseLine."Currency Code", PurchaseLine.GetDate()) * ServiceLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ServiceOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure ServOrderStatisticsPostingServOrderAsConsume()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        ServiceLine: Record "Service Line";
    begin
        // Verify Original Cost and Adjusted Cost on Services Order Statistics after posting Service Order as ship and consume.

        // Setup: Create Item, create and post Purchase Order, Service Order.
        Initialize();
        CreateAndPostPurchaseDocument(
          PurchaseLine, CreateItem('', Item."Costing Method"::Standard), LibraryRandom.RandDec(10, 2), true);  // Use TRUE for Invoice and Random value for Quantity.
        CreateServiceDocumentAndUpdateServiceLine(ServiceLine, PurchaseLine."No.", CreateCustomer(), LibraryRandom.RandDec(10, 2));  // Use Random value for Quantity.
        UpdateQtyToConsumeOnServiceLine(ServiceLine, ServiceLine."Qty. to Ship" * LibraryUtility.GenerateRandomFraction());

        // Exercise: Post Service Order as ship and consume.
        PostServiceOrder(ServiceLine, false, true);

        // Verify: Verify Original Cost and Adjusted Cost on Services Order Statistics.
        VerifyServiceOrderStatistics(
          ServiceLine."Document No.", GetItemCostLCY(PurchaseLine."No.", PurchaseLine."Currency Code", PurchaseLine.GetDate()) * ServiceLine.Quantity,
          GetItemCostLCY(PurchaseLine."No.", PurchaseLine."Currency Code", PurchaseLine.GetDate()) * ServiceLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ServiceOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure ServOrderStatisticsAfterUndoShipmentWithAdjmt()
    begin
        // Verify Original Cost and Adjusted Cost on Services Order Statistics when undo Shipment Lines and running Adjust Cost Item Entries.
        ServiceOrderStatisticsAfterUndoShipmentLine(0, false);  // 0 for Quantity To Consume and FALSE for Consume.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ServiceOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure ServOrderStatisticsAfterUndoConsumptionWithAdjmt()
    begin
        // Verify Original Cost and Adjusted Cost on Services Order Statistics when undo consumption Line and running Adjust Cost Item Entries.
        ServiceOrderStatisticsAfterUndoShipmentLine(LibraryRandom.RandInt(10), true);  // Use random for Quantity to Consume and TRUE for Consume.
    end;

    local procedure ServiceOrderStatisticsAfterUndoShipmentLine(Quantity: Decimal; Consume: Boolean)
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        ServiceLine: Record "Service Line";
    begin
        // Setup: Create Item, create and post Purchase Order, Service Order and undo Shipment Line.
        Initialize();
        CreateAndPostPurchaseDocument(
          PurchaseLine, CreateItem('', Item."Costing Method"::FIFO), Quantity + LibraryRandom.RandInt(10), true);  // Use TRUE for Invoice and Random value for Quantity.
        CreateServiceDocumentAndUpdateServiceLine(
          ServiceLine, PurchaseLine."No.", CreateCustomer(), Quantity + LibraryRandom.RandInt(10));  // Use Random Quantity greater than Quantity To Consume.
        UpdateQtyToConsumeOnServiceLine(ServiceLine, Quantity);
        PostServiceOrder(ServiceLine, false, Consume);
        if Consume then
            UndoServiceConsumptionLine(ServiceLine."Document No.")
        else
            UndoServiceShipmentLine(ServiceLine."Document No.");

        // Exercise: Run Adjust Cost Item Entries.
        LibraryCosting.AdjustCostItemEntries(ServiceLine."No.", '');  // Blank value for Item Category.

        // Verify: Verify Original Cost and Adjusted Cost on Services Order Statistics.
        VerifyServiceOrderStatistics(
            ServiceLine."Document No.", GetItemCostLCY(PurchaseLine."No.", PurchaseLine."Currency Code", PurchaseLine.GetDate()) * ServiceLine.Quantity,
            GetItemCostLCY(PurchaseLine."No.", PurchaseLine."Currency Code", PurchaseLine.GetDate()) * ServiceLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('PostedServiceInvoiceStatisticsPageHandler')]
    procedure PstdServInvStatisticsWithChargeAssignment()
    var
        PurchaseLine: Record "Purchase Line";
        ServiceLine: Record "Service Line";
    begin
        // Verify Original Cost and Adjusted Cost on posted Services Invoice Statistics after posting Service Order and Purchase Order with Charge Assignment.

        // Setup: Create and post Purchase Order with charge Assignment, create Service Order.
        Initialize();
        PostChargeOnPurchaseDocument(PurchaseLine);
        CreateServiceDocumentAndUpdateServiceLine(ServiceLine, PurchaseLine."No.", CreateCustomer(), LibraryRandom.RandDec(10, 2));  // Use Random value for Quantity.

        // Exercise: Post Service Order as ship.
        PostServiceOrder(ServiceLine, true, false);

        // Verify: Verify Original Cost and Adjusted Cost on posted Services Invoice Statistics.
        VerifyCostOnPostedServiceInvoiceStatistics(
            ServiceLine."Document No.", '', GetItemCostLCY(PurchaseLine."No.", PurchaseLine."Currency Code", PurchaseLine.GetDate()) * ServiceLine.Quantity,
            GetItemCostLCY(PurchaseLine."No.", PurchaseLine."Currency Code", PurchaseLine.GetDate()) * ServiceLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('PostedServiceCreditMemoStatisticsPageHandler')]
    procedure PstdServCrMemoStatisticsWithChargeAssignment()
    var
        PurchaseLine: Record "Purchase Line";
        ServiceLine: Record "Service Line";
    begin
        // Verify Original Cost and Adjusted Cost on posted Services Credit Memo Statistics after posting Service Credit Memo and Purchase Order with Charge Assignment.

        // Setup: Create and post Purchase Order with charge Assignment.
        Initialize();
        PostChargeOnPurchaseDocument(PurchaseLine);

        // Exercise: Create and post Service Credit Memo.
        CreateAndPostServiceCreditMemo(ServiceLine, PurchaseLine."No.", CreateCustomer());

        // Verify: Verify Original Cost and Adjusted Cost on posted Services Credit Memo Statistics
        VerifyCostOnPostedServiceCreditMemoStatistics(
          ServiceLine."Document No.", GetItemCostLCY(PurchaseLine."No.", PurchaseLine."Currency Code", PurchaseLine.GetDate()) * ServiceLine.Quantity,
          GetItemCostLCY(PurchaseLine."No.", PurchaseLine."Currency Code", PurchaseLine.GetDate()) * ServiceLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ShipmentLinePageHandler,PostedServiceInvoiceStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure PstdServInvStatisticsUsingGetShipmentLinesWithChrgAssgnt()
    var
        PurchaseLine: Record "Purchase Line";
        ServiceLine: Record "Service Line";
        OrderNo: Text[20];
    begin
        // Verify Original Cost and Adjusted Cost on on posted Services Invoice Statistics after posting Service Invoice using Get Service Shipment Lines and Purchase Order with Charge Assignment.

        // Setup: Create and post Purchase Order with charge Assignment, create Service Invoice using Get Shipment Lines.
        Initialize();
        PostChargeOnPurchaseDocument(PurchaseLine);
        CreateServiceDocumentAndUpdateServiceLine(ServiceLine, PurchaseLine."No.", CreateCustomer(), LibraryRandom.RandDec(10, 2));  // Use Random value for Quantity.
        OrderNo := ServiceLine."Document No.";
        PostServiceOrder(ServiceLine, false, false);
        LibraryVariableStorage.Enqueue(ServiceLine."Document No.");  // Enqueue value for 'ShipmentLinePageHandler'.
        CreateServiceInvoiceFromGetShipmentLines(ServiceLine, ServiceLine."Customer No.");

        // Exercise: Post Service Invoice.
        PostServiceOrder(ServiceLine, true, false);

        // Verify: Verify Original Cost and Adjusted Cost on posted Services Invoice Statistics.
        VerifyCostOnPostedServiceInvoiceStatistics(
            OrderNo, ServiceLine."Document No.", GetItemCostLCY(PurchaseLine."No.", PurchaseLine."Currency Code", PurchaseLine.GetDate()) * ServiceLine.Quantity,
            GetItemCostLCY(PurchaseLine."No.", PurchaseLine."Currency Code", PurchaseLine.GetDate()) * ServiceLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('PostedServiceInvoiceStatisticsPageHandler')]
    procedure PstdServInvStatisticsWithChargeAssignmentWithAdjmt()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        ServiceLine: Record "Service Line";
    begin
        // Verify Original Cost and Adjusted Cost on posted Services Invoice Statistics after posting Service Order and Purchase Invoice with Charge Assignment, running Adjust Cost Item Entries.

        // Setup: Create and post Purchase Order.
        Initialize();
        CreatePurchaseOrder(
          PurchaseLine, CreateVendor(), CreateItem('', Item."Costing Method"::Standard), LibraryRandom.RandDec(10, 2));  // Use Random value for Quantity.
        PostPurchaseDocument(PurchaseLine, false);

        // Create Purchase Invoice for Charge Item and assign it to previous Posted Receipt, create and post Service Order.
        CreateAndPostChargeItemPurchaseDocument(
          PurchaseLine2, PurchaseLine."Buy-from Vendor No.", PurchaseLine."Document No.", PurchaseLine."No.",
          LibraryInventory.CreateItemChargeNo());
        CreateServiceDocumentAndUpdateServiceLine(ServiceLine, PurchaseLine."No.", CreateCustomer(), LibraryRandom.RandDec(10, 2));  // Use Random value for Quantity.
        PostServiceOrder(ServiceLine, true, false);

        // Exercise: Run Adjust Cost Item Entries.
        LibraryCosting.AdjustCostItemEntries(PurchaseLine."No.", '');  // Blank value for Item Category.

        // Verify: Verify Original Cost and Adjusted Cost on posted Services Invoice Statistics.
        VerifyCostOnPostedServiceInvoiceStatistics(
            ServiceLine."Document No.", '', GetItemCostLCY(PurchaseLine."No.", PurchaseLine."Currency Code", PurchaseLine.GetDate()) * ServiceLine.Quantity,
            GetItemCostLCY(PurchaseLine."No.", PurchaseLine."Currency Code", PurchaseLine.GetDate()) * ServiceLine.Quantity);
    end;
#endif
    [Test]
    [HandlerFunctions('PostedServiceInvoiceStatisticsPageHandlerNM')]
    [Scope('OnPrem')]
    procedure PstdServInvStatisticsUsingServOrderNM()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // Verify Original Cost and Adjusted Cost on posted Services Invoice Statistics after posting Service Order.

        // Setup: Create Item, create and post Purchase Order, create Service Order.
        Initialize();
        CreatePurchaseOrder(
          PurchaseLine, CreateVendor(), CreateItem('', Item."Costing Method"::Standard), LibraryRandom.RandDec(10, 2));  // Use Random value for Quantity.
        PostPurchaseDocument(PurchaseLine, true);
        CreateServiceDocumentAndUpdateServiceLine(ServiceLine, PurchaseLine."No.", CreateCustomer(), LibraryRandom.RandDec(10, 2));  // Use random value for Quantity.
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");

        // Exercise: Post Service Order as ship and invoice.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // Verify: Verify Original Cost and Adjusted Cost on posted Services Invoice Statistics.
        VerifyCostOnPostedServiceInvoiceStatisticsNM(
          ServiceLine."Document No.", '',
          GetItemCostLCY(PurchaseLine."No.", PurchaseLine."Currency Code", PurchaseLine.GetDate()) * ServiceLine.Quantity,
          GetItemCostLCY(PurchaseLine."No.", PurchaseLine."Currency Code", PurchaseLine.GetDate()) * ServiceLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('PostedServiceInvoiceStatisticsPageHandlerNM')]
    procedure PstdServInvStatisticsWithRevAndAdjmtNM()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        UnitCostRevalued: Decimal;
    begin
        // Verify Original Cost and Adjusted Cost on posted Services Invoice Statistics after posting Revaluation Journal and running Adjust Cost Item Entries.

        // Setup: Create Item, create and post Purchase Order, Service Order and Revaluation Journal.
        CreatePurchaseOrder(
          PurchaseLine, CreateVendor(), CreateItem('', Item."Costing Method"::Standard), LibraryRandom.RandDec(10, 2));  // Use Random value for Quantity.
        PostPurchaseDocument(PurchaseLine, true);
        CreateServiceDocumentAndUpdateServiceLine(ServiceLine, PurchaseLine."No.", CreateCustomer(), PurchaseLine.Quantity / 2);  // Take Partial Quantity.
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        FindItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Purchase, PurchaseLine."No.", true);
        UnitCostRevalued :=
            GetItemCostLCY(PurchaseLine."No.", PurchaseLine."Currency Code", PurchaseLine.GetDate()) + LibraryRandom.RandDec(10, 2);  // Add random value to Unit Cost to make positive Revaluation.
        CreateAndPostRevaluationJournal(
          PurchaseLine."No.", ItemLedgerEntry."Entry No.", LibraryRandom.RandDec(100, 2), UnitCostRevalued);  // Use Random value for Inventory Value Revalued and 0 for Unit Cost Revalued.

        // Exercise: Run Adjust Cost Item Entries.
        LibraryCosting.AdjustCostItemEntries(PurchaseLine."No.", '');  // Blank value for Item Category.

        // Verify: Verify Original Cost and Adjusted Cost on posted Services Invoice Statistics.
        VerifyCostOnPostedServiceInvoiceStatisticsNM(
            ServiceLine."Document No.", '',
            GetItemCostLCY(PurchaseLine."No.", PurchaseLine."Currency Code", PurchaseLine.GetDate()) * ServiceLine.Quantity,
            UnitCostRevalued * ServiceLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('PostedServiceCreditMemoStatisticsPageHandlerNM')]
    procedure PstdServCrMemoStatisticsWithAdjmtNM()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        ServiceLine: Record "Service Line";
    begin
        // Verify Original Cost and Adjusted Cost on posted Services Credit Memo Statistics after posting Service Credit Memo and running Adjust Cost Item Entries.

        // Setup: Create Item, create and post Purchase Order, Service Credit Memo.
        Initialize();
        CreatePurchaseOrder(
          PurchaseLine, CreateVendor(), CreateItem('', Item."Costing Method"::Standard), LibraryRandom.RandDec(10, 2));  // Use Random value for Quantity.
        PostPurchaseDocument(PurchaseLine, true);
        CreateAndPostServiceCreditMemo(ServiceLine, PurchaseLine."No.", LibrarySales.CreateCustomerNo());

        // Exercise: Run Adjust Cost Item Entries.
        LibraryCosting.AdjustCostItemEntries(PurchaseLine."No.", '');  // Blank value for Item Category.

        // Verify: Verify Original Cost and Adjusted Cost on posted Services Invoice Statistics.
        VerifyCostOnPostedServiceCreditMemoStatisticsNM(
          ServiceLine."Document No.", GetItemCostLCY(PurchaseLine."No.", PurchaseLine."Currency Code", PurchaseLine.GetDate()) * ServiceLine.Quantity,
          GetItemCostLCY(PurchaseLine."No.", PurchaseLine."Currency Code", PurchaseLine.GetDate()) * ServiceLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('PostedServiceInvoiceStatisticsPageHandlerNM')]
    procedure PstdServInvStatisticsUsingServOrderWithLineDiscNM()
    var
        PurchaseLine: Record "Purchase Line";
        ServiceLine: Record "Service Line";
        SalesLineDiscount: Record "Sales Line Discount";
    begin
        // Verify Original Cost and Adjusted Cost on posted Services Invoice Statistics after posting Service Order When Line Discount is defined for Item.

        // Setup: Create Item with Sales Line Discount, create and post Purchase Order, create Service Order.
        Initialize();
        CreateItemWithSalesLineDiscount(SalesLineDiscount);
        CreateAndPostPurchaseDocument(PurchaseLine, SalesLineDiscount.Code, LibraryRandom.RandDec(10, 2), true);  // Use TRUE for Invoice and Random value for Quantity.
        CreateServiceDocumentAndUpdateServiceLine(
          ServiceLine, SalesLineDiscount.Code, SalesLineDiscount."Sales Code", LibraryRandom.RandDec(10, 2));  // Use random value for Quantity.

        // Exercise: Post Service Order as ship and invoice.
        PostServiceOrder(ServiceLine, true, false);

        // Verify: Verify Original Cost and Adjusted Cost on posted Services Invoice Statistics.
        VerifyCostOnPostedServiceInvoiceStatisticsNM(
          ServiceLine."Document No.", '', GetItemCostLCY(PurchaseLine."No.", PurchaseLine."Currency Code", PurchaseLine.GetDate()) * ServiceLine.Quantity,
          GetItemCostLCY(PurchaseLine."No.", PurchaseLine."Currency Code", PurchaseLine.GetDate()) * ServiceLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('PostedServiceInvoiceStatisticsPageHandlerNM')]
    procedure PstdServInvStatisticsWithRevAndWithoutAdjmtNM()
    var
        PurchaseLine: Record "Purchase Line";
        ServiceLine: Record "Service Line";
        SalesLineDiscount: Record "Sales Line Discount";
    begin
        // Verify Original Cost and Adjusted Cost on posted Services Invoice Statistics after posting Revaluation Journal When Line Discount is defined for Item.

        // Setup: Create Item with Sales Line Discount, create and post Purchase Order, Service Order and Revaluation Journal.
        Initialize();
        CreateItemWithSalesLineDiscount(SalesLineDiscount);
        CreateAndPostPurchaseDocument(PurchaseLine, SalesLineDiscount.Code, LibraryRandom.RandDec(10, 2), true);  // Use TRUE for Invoice and Random value for Quantity.
        CreateServiceDocumentAndUpdateServiceLine(
          ServiceLine, SalesLineDiscount.Code, SalesLineDiscount."Sales Code", PurchaseLine.Quantity - 1);  // Take less Quantity than Purchase Line.
        PostServiceOrder(ServiceLine, true, false);

        // Exercise: Create and post Revaluation Journal.
        CreateItemJournalForRevaluation(SalesLineDiscount.Code);

        // Verify: Verify Original Cost and Adjusted Cost on posted Services Invoice Statistics.
        VerifyCostOnPostedServiceInvoiceStatisticsNM(
          ServiceLine."Document No.", '',
          GetItemCostLCY(PurchaseLine."No.", PurchaseLine."Currency Code", PurchaseLine.GetDate()) * ServiceLine.Quantity,
          GetItemCostLCY(PurchaseLine."No.", PurchaseLine."Currency Code", PurchaseLine.GetDate()) * ServiceLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('PostedServiceCreditMemoStatisticsPageHandlerNM')]
    procedure PstdServCrMemoStatisticsWithoutAdjmtNM()
    var
        PurchaseLine: Record "Purchase Line";
        ServiceLine: Record "Service Line";
        SalesLineDiscount: Record "Sales Line Discount";
    begin
        // Verify Original Cost and Adjusted Cost on posted Services Credit Memo Statistics after posting Service Credit Memo When Line Discount is defined for Item..

        // Setup: Create Item with Sales Line Discount, create and post Purchase Order, Service Credit Memo.
        Initialize();
        CreateItemWithSalesLineDiscount(SalesLineDiscount);
        CreateAndPostPurchaseDocument(PurchaseLine, SalesLineDiscount.Code, LibraryRandom.RandDec(10, 2), true);  // Use TRUE for Invoice and Random value for Quantity.

        // Exercise: Create and post Service Credit Memo.
        CreateAndPostServiceCreditMemo(ServiceLine, SalesLineDiscount.Code, SalesLineDiscount."Sales Code");

        // Verify: Verify Original Cost and Adjusted Cost on posted Services Invoice Statistics.
        VerifyCostOnPostedServiceCreditMemoStatisticsNM(
          ServiceLine."Document No.", GetItemCostLCY(PurchaseLine."No.", PurchaseLine."Currency Code", PurchaseLine.GetDate()) * ServiceLine.Quantity,
          GetItemCostLCY(PurchaseLine."No.", PurchaseLine."Currency Code", PurchaseLine.GetDate()) * ServiceLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ServiceOrderStatisticsPageHandlerNM')]
    [Scope('OnPrem')]
    procedure ServOrderStatisticsPostingServOrderAsShipNM()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        ServiceLine: Record "Service Line";
    begin
        // Verify Original Cost and Adjusted Cost on Services Order Statistics after posting Service Order as Ship.

        // Setup: Create Item, create and post Purchase Order, Create Service Order.
        Initialize();
        CreateAndPostPurchaseDocument(PurchaseLine, CreateItem('', Item."Costing Method"::FIFO), LibraryRandom.RandDec(10, 2), true);  // Use TRUE for Invoice and Random value for Quantity.
        CreateServiceDocumentAndUpdateServiceLine(ServiceLine, PurchaseLine."No.", CreateCustomer(), LibraryRandom.RandDec(10, 2));  // Use Random value for Quantity.

        // Exercise: Post Service Order as ship.
        PostServiceOrder(ServiceLine, false, false);

        // Verify: Verify Original Cost and Adjusted Cost on Services Order Statistics.
        VerifyServiceOrderStatisticsNM(
          ServiceLine."Document No.", GetItemCost(PurchaseLine."No.") * ServiceLine.Quantity,
          GetItemCostLCY(PurchaseLine."No.", PurchaseLine."Currency Code", PurchaseLine.GetDate()) * ServiceLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ServiceOrderStatisticsPageHandlerNM')]
    [Scope('OnPrem')]
    procedure ServOrderStatisticsPostingServOrderAsShipWithAdjmtNM()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        ServiceLine: Record "Service Line";
        DirectUnitCost: Decimal;
        AdjustedCost: Decimal;
    begin
        // Verify Original Cost and Adjusted Cost on Services Order Statistics after posting Service Order as Ship and running Adjust Cost Item Entries.

        // Setup: Create Item, create and post Purchase Order, Service Order.
        Initialize();
        CreatePurchaseOrder(PurchaseLine, CreateVendor(), CreateItem('', Item."Costing Method"::FIFO), LibraryRandom.RandDec(10, 2));  // Use Random value for Quantity.
        DirectUnitCost := PurchaseLine."Direct Unit Cost";
        PostPartialPurchLineWithUpdate(PurchaseLine);
        AdjustedCost :=
          PurchaseLine."Quantity Invoiced" * DirectUnitCost + PurchaseLine."Qty. to Invoice" * PurchaseLine."Direct Unit Cost";
        PostPurchaseDocument(PurchaseLine, true);
        CreateServiceDocumentAndUpdateServiceLine(ServiceLine, PurchaseLine."No.", CreateCustomer(), PurchaseLine.Quantity);
        PostServiceOrder(ServiceLine, false, false);

        // Exercise: Run Adjust Cost Item Entries.
        LibraryCosting.AdjustCostItemEntries(PurchaseLine."No.", '');  // Blank value for Item Category.

        // Verify: Verify Original Cost and Adjusted Cost on Services Order Statistics.
        VerifyServiceOrderStatisticsNM(ServiceLine."Document No.", DirectUnitCost * ServiceLine.Quantity, AdjustedCost);
    end;

    [Test]
    [HandlerFunctions('ShipmentLinePageHandler,PostedServiceInvoiceStatisticsPageHandlerNM')]
    [Scope('OnPrem')]
    procedure PstdServInvStatisticsUsingGetShipmentLinesNM()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        ServiceLine: Record "Service Line";
        OrderNo: Text[20];
    begin
        // Verify Original Cost and Adjusted Cost on posted Services Invoice Statistics after posting Service Order using Get Service Shipment Lines.

        // Setup: Create Item, create and post Purchase Order, create Service Invoice using Get Shipment Lines.
        Initialize();
        CreateAndPostPurchaseDocument(PurchaseLine, CreateItem('', Item."Costing Method"::FIFO), LibraryRandom.RandDec(10, 2), true);  // Use TRUE for Invoice and Random value for Quantity.
        CreateServiceDocumentAndUpdateServiceLine(ServiceLine, PurchaseLine."No.", CreateCustomer(), LibraryRandom.RandDec(10, 2));  // Use Random value for Quantity.
        OrderNo := ServiceLine."Document No.";
        PostServiceOrder(ServiceLine, false, false);
        LibraryVariableStorage.Enqueue(ServiceLine."Document No.");  // Enqueue value for 'ShipmentLinePageHandler'.
        CreateServiceInvoiceFromGetShipmentLines(ServiceLine, ServiceLine."Customer No.");

        // Exercise: Post Service Invoice.
        PostServiceOrder(ServiceLine, true, false);

        // Verify: Verify Original Cost and Adjusted Cost on posted Services Invoice Statistics.
        VerifyCostOnPostedServiceInvoiceStatisticsNM(
          OrderNo, ServiceLine."Document No.", GetItemCostLCY(PurchaseLine."No.", PurchaseLine."Currency Code", PurchaseLine.GetDate()) * ServiceLine.Quantity,
          GetItemCostLCY(PurchaseLine."No.", PurchaseLine."Currency Code", PurchaseLine.GetDate()) * ServiceLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ServiceOrderStatisticsPageHandlerNM')]
    [Scope('OnPrem')]
    procedure ServOrderStatisticsPostingServOrderAsConsumeNM()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        ServiceLine: Record "Service Line";
    begin
        // Verify Original Cost and Adjusted Cost on Services Order Statistics after posting Service Order as ship and consume.

        // Setup: Create Item, create and post Purchase Order, Service Order.
        Initialize();
        CreateAndPostPurchaseDocument(
          PurchaseLine, CreateItem('', Item."Costing Method"::Standard), LibraryRandom.RandDec(10, 2), true);  // Use TRUE for Invoice and Random value for Quantity.
        CreateServiceDocumentAndUpdateServiceLine(ServiceLine, PurchaseLine."No.", CreateCustomer(), LibraryRandom.RandDec(10, 2));  // Use Random value for Quantity.
        UpdateQtyToConsumeOnServiceLine(ServiceLine, ServiceLine."Qty. to Ship" * LibraryUtility.GenerateRandomFraction());

        // Exercise: Post Service Order as ship and consume.
        PostServiceOrder(ServiceLine, false, true);

        // Verify: Verify Original Cost and Adjusted Cost on Services Order Statistics.
        VerifyServiceOrderStatisticsNM(
          ServiceLine."Document No.", GetItemCostLCY(PurchaseLine."No.", PurchaseLine."Currency Code", PurchaseLine.GetDate()) * ServiceLine.Quantity,
          GetItemCostLCY(PurchaseLine."No.", PurchaseLine."Currency Code", PurchaseLine.GetDate()) * ServiceLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ServiceOrderStatisticsPageHandlerNM')]
    [Scope('OnPrem')]
    procedure ServOrderStatisticsAfterUndoShipmentWithAdjmtNM()
    begin
        // Verify Original Cost and Adjusted Cost on Services Order Statistics when undo Shipment Lines and running Adjust Cost Item Entries.
        ServiceOrderStatisticsAfterUndoShipmentLineNM(0, false);  // 0 for Quantity To Consume and FALSE for Consume.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ServiceOrderStatisticsPageHandlerNM')]
    [Scope('OnPrem')]
    procedure ServOrderStatisticsAfterUndoConsumptionWithAdjmtNM()
    begin
        // Verify Original Cost and Adjusted Cost on Services Order Statistics when undo consumption Line and running Adjust Cost Item Entries.
        ServiceOrderStatisticsAfterUndoShipmentLineNM(LibraryRandom.RandInt(10), true);  // Use random for Quantity to Consume and TRUE for Consume.
    end;

    local procedure ServiceOrderStatisticsAfterUndoShipmentLineNM(Quantity: Decimal; Consume: Boolean)
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        ServiceLine: Record "Service Line";
    begin
        // Setup: Create Item, create and post Purchase Order, Service Order and undo Shipment Line.
        Initialize();
        CreateAndPostPurchaseDocument(
          PurchaseLine, CreateItem('', Item."Costing Method"::FIFO), Quantity + LibraryRandom.RandInt(10), true);  // Use TRUE for Invoice and Random value for Quantity.
        CreateServiceDocumentAndUpdateServiceLine(
          ServiceLine, PurchaseLine."No.", CreateCustomer(), Quantity + LibraryRandom.RandInt(10));  // Use Random Quantity greater than Quantity To Consume.
        UpdateQtyToConsumeOnServiceLine(ServiceLine, Quantity);
        PostServiceOrder(ServiceLine, false, Consume);
        if Consume then
            UndoServiceConsumptionLine(ServiceLine."Document No.")
        else
            UndoServiceShipmentLine(ServiceLine."Document No.");

        // Exercise: Run Adjust Cost Item Entries.
        LibraryCosting.AdjustCostItemEntries(ServiceLine."No.", '');  // Blank value for Item Category.

        // Verify: Verify Original Cost and Adjusted Cost on Services Order Statistics.
        VerifyServiceOrderStatisticsNM(
            ServiceLine."Document No.", GetItemCostLCY(PurchaseLine."No.", PurchaseLine."Currency Code", PurchaseLine.GetDate()) * ServiceLine.Quantity,
            GetItemCostLCY(PurchaseLine."No.", PurchaseLine."Currency Code", PurchaseLine.GetDate()) * ServiceLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('PostedServiceInvoiceStatisticsPageHandlerNM')]
    procedure PstdServInvStatisticsWithChargeAssignmentNM()
    var
        PurchaseLine: Record "Purchase Line";
        ServiceLine: Record "Service Line";
    begin
        // Verify Original Cost and Adjusted Cost on posted Services Invoice Statistics after posting Service Order and Purchase Order with Charge Assignment.

        // Setup: Create and post Purchase Order with charge Assignment, create Service Order.
        Initialize();
        PostChargeOnPurchaseDocument(PurchaseLine);
        CreateServiceDocumentAndUpdateServiceLine(ServiceLine, PurchaseLine."No.", CreateCustomer(), LibraryRandom.RandDec(10, 2));  // Use Random value for Quantity.

        // Exercise: Post Service Order as ship.
        PostServiceOrder(ServiceLine, true, false);

        // Verify: Verify Original Cost and Adjusted Cost on posted Services Invoice Statistics.
        VerifyCostOnPostedServiceInvoiceStatisticsNM(
            ServiceLine."Document No.", '', GetItemCostLCY(PurchaseLine."No.", PurchaseLine."Currency Code", PurchaseLine.GetDate()) * ServiceLine.Quantity,
            GetItemCostLCY(PurchaseLine."No.", PurchaseLine."Currency Code", PurchaseLine.GetDate()) * ServiceLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('PostedServiceCreditMemoStatisticsPageHandlerNM')]
    procedure PstdServCrMemoStatisticsWithChargeAssignmentNM()
    var
        PurchaseLine: Record "Purchase Line";
        ServiceLine: Record "Service Line";
    begin
        // Verify Original Cost and Adjusted Cost on posted Services Credit Memo Statistics after posting Service Credit Memo and Purchase Order with Charge Assignment.

        // Setup: Create and post Purchase Order with charge Assignment.
        Initialize();
        PostChargeOnPurchaseDocument(PurchaseLine);

        // Exercise: Create and post Service Credit Memo.
        CreateAndPostServiceCreditMemo(ServiceLine, PurchaseLine."No.", CreateCustomer());

        // Verify: Verify Original Cost and Adjusted Cost on posted Services Credit Memo Statistics
        VerifyCostOnPostedServiceCreditMemoStatisticsNM(
          ServiceLine."Document No.", GetItemCostLCY(PurchaseLine."No.", PurchaseLine."Currency Code", PurchaseLine.GetDate()) * ServiceLine.Quantity,
          GetItemCostLCY(PurchaseLine."No.", PurchaseLine."Currency Code", PurchaseLine.GetDate()) * ServiceLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ShipmentLinePageHandler,PostedServiceInvoiceStatisticsPageHandlerNM')]
    [Scope('OnPrem')]
    procedure PstdServInvStatisticsUsingGetShipmentLinesWithChrgAssgntNM()
    var
        PurchaseLine: Record "Purchase Line";
        ServiceLine: Record "Service Line";
        OrderNo: Text[20];
    begin
        // Verify Original Cost and Adjusted Cost on on posted Services Invoice Statistics after posting Service Invoice using Get Service Shipment Lines and Purchase Order with Charge Assignment.

        // Setup: Create and post Purchase Order with charge Assignment, create Service Invoice using Get Shipment Lines.
        Initialize();
        PostChargeOnPurchaseDocument(PurchaseLine);
        CreateServiceDocumentAndUpdateServiceLine(ServiceLine, PurchaseLine."No.", CreateCustomer(), LibraryRandom.RandDec(10, 2));  // Use Random value for Quantity.
        OrderNo := ServiceLine."Document No.";
        PostServiceOrder(ServiceLine, false, false);
        LibraryVariableStorage.Enqueue(ServiceLine."Document No.");  // Enqueue value for 'ShipmentLinePageHandler'.
        CreateServiceInvoiceFromGetShipmentLines(ServiceLine, ServiceLine."Customer No.");

        // Exercise: Post Service Invoice.
        PostServiceOrder(ServiceLine, true, false);

        // Verify: Verify Original Cost and Adjusted Cost on posted Services Invoice Statistics.
        VerifyCostOnPostedServiceInvoiceStatisticsNM(
            OrderNo, ServiceLine."Document No.", GetItemCostLCY(PurchaseLine."No.", PurchaseLine."Currency Code", PurchaseLine.GetDate()) * ServiceLine.Quantity,
            GetItemCostLCY(PurchaseLine."No.", PurchaseLine."Currency Code", PurchaseLine.GetDate()) * ServiceLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('PostedServiceInvoiceStatisticsPageHandlerNM')]
    procedure PstdServInvStatisticsWithChargeAssignmentWithAdjmtNM()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        ServiceLine: Record "Service Line";
    begin
        // Verify Original Cost and Adjusted Cost on posted Services Invoice Statistics after posting Service Order and Purchase Invoice with Charge Assignment, running Adjust Cost Item Entries.

        // Setup: Create and post Purchase Order.
        Initialize();
        CreatePurchaseOrder(
          PurchaseLine, CreateVendor(), CreateItem('', Item."Costing Method"::Standard), LibraryRandom.RandDec(10, 2));  // Use Random value for Quantity.
        PostPurchaseDocument(PurchaseLine, false);

        // Create Purchase Invoice for Charge Item and assign it to previous Posted Receipt, create and post Service Order.
        CreateAndPostChargeItemPurchaseDocument(
          PurchaseLine2, PurchaseLine."Buy-from Vendor No.", PurchaseLine."Document No.", PurchaseLine."No.",
          LibraryInventory.CreateItemChargeNo());
        CreateServiceDocumentAndUpdateServiceLine(ServiceLine, PurchaseLine."No.", CreateCustomer(), LibraryRandom.RandDec(10, 2));  // Use Random value for Quantity.
        PostServiceOrder(ServiceLine, true, false);

        // Exercise: Run Adjust Cost Item Entries.
        LibraryCosting.AdjustCostItemEntries(PurchaseLine."No.", '');  // Blank value for Item Category.

        // Verify: Verify Original Cost and Adjusted Cost on posted Services Invoice Statistics.
        VerifyCostOnPostedServiceInvoiceStatisticsNM(
            ServiceLine."Document No.", '', GetItemCostLCY(PurchaseLine."No.", PurchaseLine."Currency Code", PurchaseLine.GetDate()) * ServiceLine.Quantity,
            GetItemCostLCY(PurchaseLine."No.", PurchaseLine."Currency Code", PurchaseLine.GetDate()) * ServiceLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdjustCostOnTransitLocation()
    var
        Location: Record Location;
        ItemJournalLine: Record "Item Journal Line";
        Item: Record Item;
        ValueEntry: Record "Value Entry";
    begin
        // [FEATURE] [Adjust Cost Item Entries] [In-Transit Location]
        // [SCENARIO 379431] Cost Adjustment should process non-transfer Item Ledger Entries on Transit Location.
        Initialize();
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Location with "Use As In-Transit" flag unchecked.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Posted positive and negative Item entries with different unit costs.
        CreateAndPostItemJournal(
          ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.",
          LibraryRandom.RandIntInRange(10, 20), Location.Code, LibraryRandom.RandDecInRange(11, 20, 2), 0);
        CreateAndPostItemJournal(
          ItemJournalLine, ItemJournalLine."Entry Type"::"Negative Adjmt.", Item."No.",
          LibraryRandom.RandInt(10), Location.Code, LibraryRandom.RandDec(10, 2), 0);

        // [GIVEN] "Use As In-Transit" field in Location is set to TRUE.
        Location.Validate("Use As In-Transit", true);
        Location.Modify(true);

        // [WHEN] Run "Adjust Cost - Item Entries" batch job.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [THEN] Value Entry for cost adjustment is created.
        FindValueEntry(
          ValueEntry, ValueEntry."Item Ledger Entry Type"::"Negative Adjmt.", ValueEntry."Entry Type"::"Direct Cost",
          Item."No.", true, Location.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingGroupsInInvPostBufferFilledByPostInventoryToGLTest()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        InventoryPostingGroup: Record "Inventory Posting Group";
        ValueEntry: Record "Value Entry";
        TempInvtPostToGLTestBuffer: Record "Invt. Post to G/L Test Buffer" temporary;
    begin
        // [FEATURE] [Post Inventory To G/L Test] [UT]
        // [SCENARIO 210793] Invt. Post to G/L Test Buffer filled by "Post Inventory To G/L" batch job should contain either Gen. Product Posting Group code or Inventory Posting Group, but not both. Otherwise, a posting error may not be identified properly
        Initialize();

        // [GIVEN] General posting setup with "Gen. Bus. Posting Group" = '' and "Gen. Prod. Posting Group" = "X".
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);
        LibraryERM.CreateGeneralPostingSetup(GeneralPostingSetup, '', GenProductPostingGroup.Code);

        // [GIVEN] Inventory Posting Group "Y".
        LibraryInventory.CreateInventoryPostingGroup(InventoryPostingGroup);

        // [GIVEN] Value Entry for capacity with "Gen. Prod. Posting Group" = "X", "Inventory Posting Group" = "Y" and Location Code = "Z".
        MockValueEntry(ValueEntry, GenProductPostingGroup.Code, InventoryPostingGroup.Code);

        // [WHEN] Run Post Inventory to G/L Test report on the Value Entry.
        ValueEntry.SetRange("Entry No.", ValueEntry."Entry No.");
        GetPostInvtToGLTestBuffer(TempInvtPostToGLTestBuffer, ValueEntry);
        // [THEN] Invt. Post To G/L Test Buffer is filled with two records:
        // [THEN] The first one has "Gen. Prod. Posting Group" = "X", and blank Inventory Posting Group and Location Code.
        TempInvtPostToGLTestBuffer.Reset();
        TempInvtPostToGLTestBuffer.SetRange("Gen. Prod. Posting Group", GenProductPostingGroup.Code);
        TempInvtPostToGLTestBuffer.FindFirst();
        TempInvtPostToGLTestBuffer.TestField("Invt. Posting Group Code", '');
        TempInvtPostToGLTestBuffer.TestField("Location Code", '');
        // [THEN] The second one has "Inventory Posting Group" = "Y" and Location Code = "Z", and blank "Gen. Prod. Posting Group".
        TempInvtPostToGLTestBuffer.Reset();
        TempInvtPostToGLTestBuffer.SetRange("Invt. Posting Group Code", InventoryPostingGroup.Code);
        TempInvtPostToGLTestBuffer.FindFirst();
        TempInvtPostToGLTestBuffer.TestField("Location Code", ValueEntry."Location Code");
        TempInvtPostToGLTestBuffer.TestField("Gen. Prod. Posting Group", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingBlankGroupsInInvPostBufferFilledByPostInventoryToGL()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        InventoryPostingGroup: Record "Inventory Posting Group";
        InventoryPostingSetup: Record "Inventory Posting Setup";
        Location: Record Location;
        ValueEntry: Record "Value Entry";
        InventoryPostingToGL: Codeunit "Inventory Posting To G/L";
    begin
        // [FEATURE] [Post Inventory To G/L] [Blocked] [UT]
        // [SCENARIO 403129] Blank Gen Posting Setup leads to an error during Inventory Posting To G/L
        Initialize();

        // [GIVEN] General posting setup with "Gen. Bus. Posting Group" = '' and "Gen. Prod. Posting Group" = "X".
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);
        LibraryERM.CreateGeneralPostingSetup(GeneralPostingSetup, '', GenProductPostingGroup.Code);

        // [GIVEN] Inventory Posting Group "Y".
        LibraryInventory.CreateInventoryPostingGroup(InventoryPostingGroup);

        // [GIVEN] Value Entry for capacity with "Gen. Prod. Posting Group" = "X", "Inventory Posting Group" = "Y" and Location Code = "Z".
        MockValueEntry(ValueEntry, GenProductPostingGroup.Code, InventoryPostingGroup.Code);
        // [GIVEN] Exists InventoryPostingSetup for "Z","Y", where is not blank
        Location.Code := ValueEntry."Location Code";
        Location.Insert();
        LibraryInventory.CreateInventoryPostingSetup(InventoryPostingSetup, ValueEntry."Location Code", InventoryPostingGroup.Code);
        InventoryPostingSetup."Inventory Account" := LibraryERM.CreateGLAccountNo();
        InventoryPostingSetup.Modify();

        // [GIVEN] GeneralPostingSetup is blank
        GeneralPostingSetup.Get(ValueEntry."Gen. Bus. Posting Group", ValueEntry."Gen. Prod. Posting Group");
        GeneralPostingSetup.Blocked := true;
        GeneralPostingSetup.Modify();

        // [WHEN] Run Post Inventory to G/L on the Value Entry.
        ValueEntry.SetRange("Entry No.", ValueEntry."Entry No.");
        InventoryPostingToGL.SetRunOnlyCheck(true, true, false);
        asserterror InventoryPostingToGL.BufferInvtPosting(ValueEntry);

        // [THEN] Error: 'Blocked must be equal to No in General Posting Setup'
        Assert.ExpectedTestFieldError(GeneralPostingSetup.FieldCaption(Blocked), Format(false));
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Inventory Batch Jobs");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Inventory Batch Jobs");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Inventory Batch Jobs");
    end;

    local procedure CreateAndApplySalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; No: Code[20]; Quantity: Decimal; ApplToItemEntry: Integer)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, No, Quantity);
        SalesLine.Validate("Appl.-to Item Entry", ApplToItemEntry);
        SalesLine.Modify(true);
    end;

    local procedure CreateAndPostItemJournal(var ItemJournalLine: Record "Item Journal Line"; EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; UnitAmount: Decimal; AppliesToEntry: Integer)
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, EntryType, ItemNo, Quantity);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Unit Amount", UnitAmount);
        ItemJournalLine.Validate("Applies-to Entry", AppliesToEntry);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateAndPostPurchaseDocument(var PurchaseLine: Record "Purchase Line"; No: Code[20]; Quantity: Decimal; Invoice: Boolean)
    begin
        CreatePurchaseOrder(PurchaseLine, CreateVendor(), No, Quantity);
        PostPurchaseDocument(PurchaseLine, Invoice);
    end;

    local procedure CreateAndPostPurchaseOrderWithLineAmount(var PurchaseLine: Record "Purchase Line")
    var
        Item: Record Item;
    begin
        CreatePurchaseOrder(PurchaseLine, CreateVendor(), CreateItem('', Item."Costing Method"::FIFO), 1 + LibraryRandom.RandInt(5));  // Take more than 1 Random integer Quantity to create Rounding Entry.
        PurchaseLine.Validate("Line Amount", PurchaseLine."Line Amount" - PurchaseLine."Line Amount" / 100);  // Decrease Line Amount for getting divided value
        PurchaseLine.Modify(true);
        PostPurchaseDocument(PurchaseLine, true);
    end;

    local procedure CreateAndPostChargeItemPurchaseDocument(var PurchaseLine: Record "Purchase Line"; VendorNo: Code[20]; PurchaseOdrerNo: Code[20]; ItemNo: Code[20]; ItemChargeNo: Code[20]) PostedPurchInvoiceNo: Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Charge (Item)", ItemChargeNo, 1);  // Taking 1 for Item Charge.
        CreateItemChargeAssignment(PurchaseLine, PurchaseOdrerNo, ItemNo);
        PostedPurchInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateAndPostRevaluationJournal(ItemNo: Code[20]; AppliesToEntry: Integer; InventoryValueRevalued: Decimal; UnitCostRevalued: Decimal): Decimal
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Type::Revaluation);
        ItemJournalLine.Validate("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.Validate("Journal Batch Name", ItemJournalBatch.Name);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, ItemJournalLine."Entry Type"::Purchase, ItemNo,
          -1);
        ItemJournalLine.Validate("Value Entry Type", ItemJournalLine."Value Entry Type"::Revaluation);
        ItemJournalLine.Validate("Applies-to Entry", AppliesToEntry);
        ItemJournalLine.Validate("Inventory Value (Revalued)", InventoryValueRevalued);
        ItemJournalLine.Validate("Unit Cost (Revalued)", UnitCostRevalued);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        exit((ItemJournalLine."Inventory Value (Revalued)" - ItemJournalLine."Inventory Value (Calculated)") / ItemJournalLine.Quantity);
    end;

    local procedure CreateAndPostSalesDocument(var SalesLine: Record "Sales Line"; No: Code[20]; Quantity: Decimal; ApplToItemEntry: Integer; Invoice: Boolean)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer());
        CreateAndApplySalesLine(SalesLine, SalesHeader, No, Quantity, ApplToItemEntry);
        PostSalesDocument(SalesLine, Invoice);
    end;

    local procedure CreateAndPostSalesOrderWithMultiLine(ItemNo: Code[20]; TotalCount: Integer; EntryNo: Integer)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        "Count": Integer;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer());
        for Count := 1 to TotalCount do
            CreateAndApplySalesLine(SalesLine, SalesHeader, ItemNo, 1, EntryNo);  // 1 is for Single Line Quantity.
        PostSalesDocument(SalesLine, true);
    end;

    local procedure CreateAndPostSalesReturnOrder(var SalesLine: Record "Sales Line"; No: Code[20]; Quantity: Decimal; ApplFromItemEntry: Integer)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", CreateCustomer());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, No, Quantity);
        SalesLine.Validate("Appl.-from Item Entry", ApplFromItemEntry);
        SalesLine.Modify(true);
        PostSalesDocument(SalesLine, true);
    end;

    local procedure CreateAndPostServiceCreditMemo(var ServiceLine: Record "Service Line"; ItemNo: Code[20]; CustomerNo: Code[20])
    var
        ServiceHeader: Record "Service Header";
    begin
        CreateServiceDocument(
          ServiceLine, ServiceHeader."Document Type"::"Credit Memo", CustomerNo, ItemNo, LibraryRandom.RandDec(100, 2));  // Use random value for Quantity.
        PostServiceOrder(ServiceLine, true, false);
    end;

    local procedure CreateAndPostTransferOrder(var TransferHeader: Record "Transfer Header"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        InTransitLocation: Record Location;
        Location: Record Location;
        TransferLine: Record "Transfer Line";
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);
        LibraryWarehouse.CreateTransferHeader(TransferHeader, LocationCode, Location.Code, InTransitLocation.Code);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Quantity);
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, true);
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        exit(Customer."No.");
    end;

    local procedure CreateItem(ItemCategoryCode: Code[20]; CostingMethod: Enum "Costing Method"): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Category Code", ItemCategoryCode);
        Item.Validate("Costing Method", CostingMethod);
        Item.Validate("Unit Price", LibraryRandom.RandDec(10, 2));  // Using Random value for Unit Price.
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateItemChargeAssignment(var PurchaseLine: Record "Purchase Line"; PurchaseOrderNo: Code[20]; ItemNo: Code[20])
    var
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        FindPurchaseReceiptLine(PurchRcptLine, PurchaseOrderNo, ItemNo);
        LibraryInventory.CreateItemChargeAssignPurchase(
          ItemChargeAssignmentPurch, PurchaseLine, ItemChargeAssignmentPurch."Applies-to Doc. Type"::Receipt,
          PurchRcptLine."Document No.", PurchRcptLine."Line No.", PurchRcptLine."No.");
    end;

    local procedure CreateItemWithSalesLineDiscount(var SalesLineDiscount: Record "Sales Line Discount")
    var
        Item: Record Item;
    begin
        // Use Random value for Minimum Quantity and Discount Percentage.
        LibraryERM.CreateLineDiscForCustomer(
          SalesLineDiscount, SalesLineDiscount.Type::Item, CreateItem('', Item."Costing Method"::Standard),
          SalesLineDiscount."Sales Type"::Customer, CreateCustomer(), WorkDate(), '', '', '', LibraryRandom.RandDec(10, 2));
        SalesLineDiscount.Validate("Line Discount %", LibraryRandom.RandDec(10, 2));
        SalesLineDiscount.Modify(true);
    end;

    local procedure CreateItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; ItemJournalTemplateType: Enum "Item Journal Template Type")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplateType);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        LibraryUtility.GenerateGUID();  // To rectify Item Journal Batch error.
    end;

    local procedure CreateItemJournalForRevaluation(ItemNo: Code[20])
    var
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        Item.SetRange("No.", ItemNo);
        CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Type::Revaluation);
        LibraryCosting.CreateRevaluationJournal(
          ItemJournalBatch, Item, WorkDate(), LibraryUtility.GenerateGUID(), "Inventory Value Calc. Per"::"Item Ledger Entry", false, false, false, "Inventory Value Calc. Base"::" ",
          false);
        ItemJournalLine.SetRange("Value Entry Type", ItemJournalLine."Value Entry Type"::Revaluation);
        ItemJournalLine.SetRange("Item No.", ItemNo);
        ItemJournalLine.FindFirst();
        ItemJournalLine.Validate("Unit Cost (Revalued)", ItemJournalLine."Unit Cost (Calculated)" + LibraryRandom.RandDec(10, 2));  // Use Random value for Unit Cost Revalued.
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateItemWithInventoryValueZero(InventoryValueZero: Boolean): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Inventory Value Zero", InventoryValueZero);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateVendorInvoiceDisc(VendorCode: Code[20]): Code[20]
    var
        VendorInvoiceDisc: Record "Vendor Invoice Disc.";
    begin
        LibraryERM.CreateInvDiscForVendor(VendorInvoiceDisc, VendorCode, '', LibraryRandom.RandInt(10));  // Using Random value for Minimum amount
        VendorInvoiceDisc.Validate("Discount %", LibraryRandom.RandInt(10));   // Using random value Random Disocunt %
        VendorInvoiceDisc.Modify(true);
        exit(VendorInvoiceDisc.Code);
    end;

    local procedure CreatePurchaseOrderAndModifyLine(var PurchaseLine: Record "Purchase Line"; InventoryValueZero: Boolean)
    begin
        CreatePurchaseOrder(
          PurchaseLine, CreateVendorWithInvoiceDiscount(), CreateItemWithInventoryValueZero(InventoryValueZero),
          LibraryRandom.RandInt(10));  // Using Random value for Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(50));  // Using Random value for Direct Unit Cost.
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseOrder(var PurchaseLine: Record "Purchase Line"; BuyFromVendorNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, BuyFromVendorNo);
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; BuyFromVendorNo: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, BuyFromVendorNo);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; Type: Enum "Purchase Line Type"; No: Code[20]; Quantity: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, Quantity);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));  // Using Random value for Direct Unit Cost.
        PurchaseLine.Modify(true);
    end;

    local procedure CreateServiceDocument(var ServiceLine: Record "Service Line"; DocumentType: Enum "Service Document Type"; CustomerNo: Code[20]; No: Code[20]; Quantity: Decimal)
    var
        ServiceHeader: Record "Service Header";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, CustomerNo);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, No);
        ServiceLine.Validate(Quantity, Quantity);
        ServiceLine.Modify(true);
    end;

    local procedure CreateServiceAndPurchaseOrder(var PurchaseLine2: Record "Purchase Line")
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // Ship a Service Order, Receive a Purchase Order and Receive and Invoice another Purchase Order.
        CreateServiceDocumentAndUpdateServiceLine(
          ServiceLine, CreateItem('', Item."Costing Method"::FIFO), CreateCustomer(), LibraryRandom.RandDec(10, 2));  // Using Random value for Quantity.
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        CreateAndPostPurchaseDocument(PurchaseLine, ServiceLine."No.", ServiceLine.Quantity, false);  // False for Invoice.

        // Create another Purchase Order and Post as Receive and Invoice with Direct Unit Cost greater than above Purchase Order's Direct Unit Cost.
        CreatePurchaseOrder(PurchaseLine2, PurchaseLine."Buy-from Vendor No.", PurchaseLine."No.", PurchaseLine.Quantity);
        PurchaseLine2.Validate("Direct Unit Cost", PurchaseLine."Direct Unit Cost" + 10);
        PurchaseLine2.Modify();
    end;

    local procedure CreateServiceDocumentAndUpdateServiceLine(var ServiceLine: Record "Service Line"; ItemNo: Code[20]; CustomerNo: Code[20]; Quantity: Decimal)
    var
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
    begin
        CreateServiceDocument(ServiceLine, ServiceHeader."Document Type"::Order, CustomerNo, ItemNo, Quantity);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Modify(true);
    end;

    local procedure CreateServiceInvoiceFromGetShipmentLines(var ServiceLine: Record "Service Line"; CustomerNo: Code[20])
    var
        ServiceHeader: Record "Service Header";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, CustomerNo);
        ServiceLine.Validate("Document Type", ServiceHeader."Document Type");
        ServiceLine.Validate("Document No.", ServiceHeader."No.");
        CODEUNIT.Run(CODEUNIT::"Service-Get Shipment", ServiceLine);
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        exit(Vendor."No.");
    end;

    local procedure CreateVendorWithInvoiceDiscount(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Invoice Disc. Code", CreateVendorInvoiceDisc(Vendor."No."));
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure MockValueEntry(var ValueEntry: Record "Value Entry"; GenProdPostingGroupCode: Code[20]; InventoryPostingGroupCode: Code[20])
    begin
        ValueEntry.Init();
        ValueEntry."Entry No." := LibraryUtility.GetNewRecNo(ValueEntry, ValueEntry.FieldNo("Entry No."));
        ValueEntry."Item Ledger Entry No." := 0;
        ValueEntry."Capacity Ledger Entry No." := LibraryRandom.RandInt(100);
        ValueEntry."Posting Date" := WorkDate();
        ValueEntry."Entry Type" := ValueEntry."Entry Type"::"Direct Cost";
        ValueEntry."Gen. Prod. Posting Group" := GenProdPostingGroupCode;
        ValueEntry."Inventory Posting Group" := InventoryPostingGroupCode;
        ValueEntry."Location Code" := LibraryUtility.GenerateGUID();
        ValueEntry.Type := ValueEntry.Type::"Work Center";
        ValueEntry."No." := LibraryUtility.GenerateGUID();
        ValueEntry."Valued Quantity" := LibraryRandom.RandInt(10);
        ValueEntry."Cost per Unit" := LibraryRandom.RandDec(10, 2);
        ValueEntry."Cost Amount (Actual)" := ValueEntry."Valued Quantity" * ValueEntry."Cost per Unit";
        ValueEntry.Insert();
    end;

    local procedure GetPostInvtToGLTestBuffer(var TempInvtPostToGLTestBuffer: Record "Invt. Post to G/L Test Buffer" temporary; var ValueEntry: Record "Value Entry")
    var
        InventoryPostingToGL: Codeunit "Inventory Posting To G/L";
    begin
        InventoryPostingToGL.SetRunOnlyCheck(false, true, true);
        InventoryPostingToGL.BufferInvtPosting(ValueEntry);
        InventoryPostingToGL.PostInvtPostBufPerEntry(ValueEntry);
        InventoryPostingToGL.GetTempInvtPostToGLTestBuf(TempInvtPostToGLTestBuffer);
    end;

    local procedure FindValueEntry(var ValueEntry: Record "Value Entry"; ItemLedgerEntryType: Enum "Item Ledger Document Type"; EntryType: Enum "Cost Entry Type"; ItemNo: Code[20]; Adjustment: Boolean; LocationCode: Code[10])
    begin
        ValueEntry.SetRange("Item Ledger Entry Type", ItemLedgerEntryType);
        ValueEntry.SetRange("Entry Type", EntryType);
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.SetRange(Adjustment, Adjustment);
        ValueEntry.SetRange("Location Code", LocationCode);
        ValueEntry.FindFirst();
    end;

    local procedure FindItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; Open: Boolean)
    begin
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange(Open, Open);
        ItemLedgerEntry.FindFirst();
    end;

    local procedure FindPurchaseReceiptLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; OrderNo: Code[20]; ItemNo: Code[20])
    begin
        PurchRcptLine.SetRange("Order No.", OrderNo);
        PurchRcptLine.SetRange("No.", ItemNo);
        PurchRcptLine.FindFirst();
    end;

    local procedure FindServiceShipmentLine(var ServiceShipmentLine: Record "Service Shipment Line"; OrderNo: Code[20])
    begin
        ServiceShipmentLine.SetRange("Order No.", OrderNo);
        ServiceShipmentLine.FindFirst();
    end;

    local procedure GetItemCost(ItemNo: Code[20]): Decimal
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        exit(Item."Unit Cost");
    end;

    local procedure GetItemCostLCY(ItemNo: Code[20]; CurrencyCode: Code[10]; Date: Date): Decimal
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        exit(CurrencyExchangeRate.ExchangeAmtFCYToLCY(Date, CurrencyCode, GetItemCost(ItemNo), CurrencyExchangeRate.ExchangeRate(Date, CurrencyCode)));
    end;

    local procedure PostChargeOnPurchaseDocument(var PurchaseLine: Record "Purchase Line")
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine2: Record "Purchase Line";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
    begin
        CreatePurchaseOrder(
          PurchaseLine, CreateVendor(), CreateItem('', Item."Costing Method"::Standard), LibraryRandom.RandDec(10, 2));  // Use Random value for Quantity.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        CreatePurchaseLine(
          PurchaseLine2, PurchaseHeader, PurchaseLine.Type::"Charge (Item)", LibraryInventory.CreateItemChargeNo(), 1);  // Taking 1 for Item Charge.
        LibraryInventory.CreateItemChargeAssignPurchase(
          ItemChargeAssignmentPurch, PurchaseLine2, ItemChargeAssignmentPurch."Applies-to Doc. Type"::Order, PurchaseLine."Document No.",
          PurchaseLine."Line No.", PurchaseLine."No.");
        PostPurchaseDocument(PurchaseLine, true);
    end;

    local procedure RunPostInventoryCostToGL(PostMethod: Option; ItemNo: Code[20]; DocumentNo: Code[20])
    var
        PostValueEntryToGL: Record "Post Value Entry to G/L";
        PostInventoryCostToGL: Report "Post Inventory Cost to G/L";
    begin
        Commit();
        PostValueEntryToGL.SetRange("Item No.", ItemNo);
        PostInventoryCostToGL.InitializeRequest(PostMethod, DocumentNo, true);
        PostInventoryCostToGL.SetTableView(PostValueEntryToGL);
        PostInventoryCostToGL.UseRequestPage(false);
    end;

    local procedure PostPartialPurchLineWithUpdate(var PurchaseLine: Record "Purchase Line")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseLine.Validate("Qty. to Invoice", PurchaseLine."Qty. to Invoice" / 2);  // post partial Quantity.
        PurchaseLine.Modify(true);
        PostPurchaseDocument(PurchaseLine, true);
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));  // Using Random value for Direct Unit Cost.
        PurchaseLine.Modify(true);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
    end;

    local procedure PostPurchaseDocument(PurchaseLine: Record "Purchase Line"; Invoice: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, Invoice);
    end;

    local procedure PostSalesDocument(SalesLine: Record "Sales Line"; Invoice: Boolean)
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.PostSalesDocument(SalesHeader, true, Invoice);
    end;

    local procedure PostServiceOrder(ServiceLine: Record "Service Line"; Invoice: Boolean; Consume: Boolean)
    var
        ServiceHeader: Record "Service Header";
    begin
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, Consume, Invoice);
    end;

    local procedure UndoServiceShipmentLine(OrderNo: Code[20])
    var
        ServiceShipmentLine: Record "Service Shipment Line";
    begin
        LibraryVariableStorage.Enqueue(UndoShipmentQst);  // Enqueue value for Confirm handler.
        FindServiceShipmentLine(ServiceShipmentLine, OrderNo);
        CODEUNIT.Run(CODEUNIT::"Undo Service Shipment Line", ServiceShipmentLine);
    end;

    local procedure UndoServiceConsumptionLine(OrderNo: Code[20])
    var
        ServiceShipmentLine: Record "Service Shipment Line";
    begin
        LibraryVariableStorage.Enqueue(UndoConsumptionQst);  // Enqueue value for Confirm handler.
        FindServiceShipmentLine(ServiceShipmentLine, OrderNo);
        CODEUNIT.Run(CODEUNIT::"Undo Service Consumption Line", ServiceShipmentLine);
    end;

    local procedure UpdateInventorySetup(AutomaticCostPosting: Boolean)
    begin
        LibraryInventory.SetAutomaticCostPosting(AutomaticCostPosting);
        LibraryInventory.SetExpectedCostPosting(true);
    end;

    local procedure UpdateQtyToConsumeOnServiceLine(ServiceLine: Record "Service Line"; QtyToConsume: Decimal)
    begin
        ServiceLine.Validate("Qty. to Consume", QtyToConsume);
        ServiceLine.Modify(true);
    end;

    local procedure VerifyCostAmountActual(ValueEntry: Record "Value Entry"; ItemLedgerEntryType: Enum "Item Ledger Document Type"; EntryType: Enum "Cost Entry Type"; ItemNo: Code[20]; Adjustment: Boolean; LocationCode: Code[10]; CostAmountActual: Decimal)
    begin
        FindValueEntry(ValueEntry, ItemLedgerEntryType, EntryType, ItemNo, Adjustment, LocationCode);
        Assert.AreNearlyEqual(
          CostAmountActual, ValueEntry."Cost Amount (Actual)", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(FieldValidationErr, ValueEntry.FieldCaption("Cost Amount (Actual)"), CostAmountActual));
    end;

    local procedure VerifyValueEntryForItemCharge(ItemNo: Code[20]; ItemChargeNo: Code[20]; CostAmountActual: Decimal)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::Purchase);
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.SetRange("Item Charge No.", ItemChargeNo);
        ValueEntry.FindFirst();
        ValueEntry.TestField("Cost Amount (Actual)", CostAmountActual);
    end;

    local procedure VerifyItemLedgerEntry(EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; CostAmountExpected: Decimal; InvoicedQuantity: Decimal; CostAmountActual: Decimal; Open: Boolean; AppliedEntryToAdjust: Boolean)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FindItemLedgerEntry(ItemLedgerEntry, EntryType, ItemNo, Open);
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)", "Cost Amount (Expected)");
        ItemLedgerEntry.TestField("Invoiced Quantity", InvoicedQuantity);
        ItemLedgerEntry.TestField("Applied Entry to Adjust", AppliedEntryToAdjust);
        Assert.AreNearlyEqual(
          CostAmountActual, ItemLedgerEntry."Cost Amount (Actual)", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(FieldValidationErr, ItemLedgerEntry.FieldCaption("Cost Amount (Actual)"), CostAmountActual));
        Assert.AreNearlyEqual(
          CostAmountExpected, ItemLedgerEntry."Cost Amount (Expected)", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(FieldValidationErr, ItemLedgerEntry.FieldCaption("Cost Amount (Expected)"), CostAmountExpected));
    end;

    local procedure VerifyValueEntryCost(ItemNo: Code[20])
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::Purchase);
        FindValueEntry(ValueEntry, ValueEntry."Item Ledger Entry Type"::Purchase, ValueEntry."Entry Type"::"Direct Cost", ItemNo, false, '');
        ValueEntry.TestField("Cost Posted to G/L", ValueEntry."Invoiced Quantity" * ValueEntry."Cost per Unit");
    end;

    local procedure VerifyValueByAverageValueEntry(ItemNo: Code[20]; Quantity: Decimal; ValuedByAverageCost: Boolean)
    var
        ValueEntry: Record "Value Entry";
    begin
        FindValueEntry(ValueEntry, ValueEntry."Item Ledger Entry Type"::Sale, ValueEntry."Entry Type"::"Direct Cost", ItemNo, true, '');
        ValueEntry.TestField("Valued By Average Cost", ValuedByAverageCost);
        ValueEntry.TestField("Valued Quantity", Quantity);
    end;

    local procedure VerifyItemCategoryOnItemLedger(ItemNo: Code[20]; ItemCategoryCode: Code[20])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FindItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Sale, ItemNo, false);
        ItemLedgerEntry.TestField("Item Category Code", ItemCategoryCode);
    end;

#if not CLEAN27
    local procedure VerifyCostOnPostedServiceInvoiceStatistics(OrderNo: Code[20]; PreAssignedNo: Code[20]; CostLCY: Decimal; TotalAdjCostLCY: Decimal)
    var
        ServiceInvHeader: Record "Service Invoice Header";
        PostedServiceInvoice: TestPage "Posted Service Invoice";
    begin
        LibraryVariableStorage.Enqueue(CostLCY);
        LibraryVariableStorage.Enqueue(TotalAdjCostLCY);
        ServiceInvHeader.SetRange("Order No.", OrderNo);
        ServiceInvHeader.SetRange("Pre-Assigned No.", PreAssignedNo);
        ServiceInvHeader.FindFirst();
        PostedServiceInvoice.OpenView();
        PostedServiceInvoice.GotoRecord(ServiceInvHeader);
        PostedServiceInvoice.Statistics.Invoke();
    end;

    local procedure VerifyCostOnPostedServiceCreditMemoStatistics(ServiceDocNo: Code[20]; CostLCY: Decimal; TotalAdjCostLCY: Decimal)
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        PostedServiceCreditMemo: TestPage "Posted Service Credit Memo";
    begin
        LibraryVariableStorage.Enqueue(CostLCY);
        LibraryVariableStorage.Enqueue(TotalAdjCostLCY);
        ServiceCrMemoHeader.SetRange("Pre-Assigned No.", ServiceDocNo);
        ServiceCrMemoHeader.FindFirst();
        PostedServiceCreditMemo.OpenView();
        PostedServiceCreditMemo.GotoRecord(ServiceCrMemoHeader);
        PostedServiceCreditMemo.Statistics.Invoke();
    end;

    local procedure VerifyServiceOrderStatistics(No: Code[20]; OriginalCost: Decimal; AdjustedCost: Decimal)
    var
        ServiceOrder: TestPage "Service Order";
    begin
        // Enqueue values for 'ServiceOrderStatisticsPageHandler' and verification done in 'ServiceOrderStatisticsPageHandler'.
        LibraryVariableStorage.Enqueue(OriginalCost);
        LibraryVariableStorage.Enqueue(AdjustedCost);
        ServiceOrder.OpenView();
        ServiceOrder.FILTER.SetFilter("No.", No);
        ServiceOrder.Statistics.Invoke();
    end;
#endif
    local procedure VerifyCostOnPostedServiceInvoiceStatisticsNM(OrderNo: Code[20]; PreAssignedNo: Code[20]; CostLCY: Decimal; TotalAdjCostLCY: Decimal)
    var
        ServiceInvHeader: Record "Service Invoice Header";
        PostedServiceInvoice: TestPage "Posted Service Invoice";
    begin
        LibraryVariableStorage.Enqueue(CostLCY);
        LibraryVariableStorage.Enqueue(TotalAdjCostLCY);
        ServiceInvHeader.SetRange("Order No.", OrderNo);
        ServiceInvHeader.SetRange("Pre-Assigned No.", PreAssignedNo);
        ServiceInvHeader.FindFirst();
        PostedServiceInvoice.OpenView();
        PostedServiceInvoice.GotoRecord(ServiceInvHeader);
        PostedServiceInvoice.ServiceStatistics.Invoke();
    end;

    local procedure VerifyCostOnPostedServiceCreditMemoStatisticsNM(ServiceDocNo: Code[20]; CostLCY: Decimal; TotalAdjCostLCY: Decimal)
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        PostedServiceCreditMemo: TestPage "Posted Service Credit Memo";
    begin
        LibraryVariableStorage.Enqueue(CostLCY);
        LibraryVariableStorage.Enqueue(TotalAdjCostLCY);
        ServiceCrMemoHeader.SetRange("Pre-Assigned No.", ServiceDocNo);
        ServiceCrMemoHeader.FindFirst();
        PostedServiceCreditMemo.OpenView();
        PostedServiceCreditMemo.GotoRecord(ServiceCrMemoHeader);
        PostedServiceCreditMemo.ServiceStatistics.Invoke();
    end;

    local procedure VerifyServiceOrderStatisticsNM(No: Code[20]; OriginalCost: Decimal; AdjustedCost: Decimal)
    var
        ServiceOrder: TestPage "Service Order";
    begin
        // Enqueue values for 'ServiceOrderStatisticsPageHandler' and verification done in 'ServiceOrderStatisticsPageHandler'.
        LibraryVariableStorage.Enqueue(OriginalCost);
        LibraryVariableStorage.Enqueue(AdjustedCost);
        ServiceOrder.OpenView();
        ServiceOrder.FILTER.SetFilter("No.", No);
        ServiceOrder.ServiceOrderStatistics.Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);  // Dequeue Variable.
        Assert.IsTrue(StrPos(ConfirmMessage, ExpectedMessage) > 0, ConfirmMessage);
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ShipmentLinePageHandler(var GetServiceShipmentLines: Page "Get Service Shipment Lines"; var Response: Action)
    var
        ServiceShipmentHeader: Record "Service Shipment Header";
        ServiceShipmentLine: Record "Service Shipment Line";
        OrderNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(OrderNo);
        ServiceShipmentHeader.SetRange("Order No.", OrderNo);
        ServiceShipmentHeader.FindFirst();
        ServiceShipmentLine.SetRange("Document No.", ServiceShipmentHeader."No.");
        ServiceShipmentLine.FindFirst();

        GetServiceShipmentLines.SetRecord(ServiceShipmentLine);
        GetServiceShipmentLines.GetShipmentLines();
    end;

#if not CLEAN27
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceOrderStatisticsPageHandler(var ServiceOrderStatistics: TestPage "Service Order Statistics")
    var
        CostLCY: Variant;
        TotalAdjCostLCY: Variant;
    begin
        LibraryVariableStorage.Dequeue(CostLCY);
        LibraryVariableStorage.Dequeue(TotalAdjCostLCY);
        Assert.AreNearlyEqual(
          CostLCY, ServiceOrderStatistics.OriginalCostLCY.AsDecimal(), LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(FieldValidationErr, CostLbl, CostLCY));
        Assert.AreNearlyEqual(
          TotalAdjCostLCY, ServiceOrderStatistics.AdjustedCostLCY.AsDecimal(), LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(FieldValidationErr, CostLbl, TotalAdjCostLCY));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedServiceInvoiceStatisticsPageHandler(var ServiceInvoiceStatistics: TestPage "Service Invoice Statistics")
    var
        CostLCY: Variant;
        TotalAdjCostLCY: Variant;
    begin
        LibraryVariableStorage.Dequeue(CostLCY);
        LibraryVariableStorage.Dequeue(TotalAdjCostLCY);
        Assert.AreNearlyEqual(
          CostLCY, ServiceInvoiceStatistics.CostLCY.AsDecimal(), LibraryERM.GetAmountRoundingPrecision(), StrSubstNo(FieldValidationErr, CostLbl, CostLCY));
        Assert.AreNearlyEqual(
          TotalAdjCostLCY, ServiceInvoiceStatistics.TotalAdjCostLCY.AsDecimal(), LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(FieldValidationErr, CostLbl, TotalAdjCostLCY));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedServiceCreditMemoStatisticsPageHandler(var ServiceCreditMemoStatistics: TestPage "Service Credit Memo Statistics")
    var
        CostLCY: Variant;
        TotalAdjCostLCY: Variant;
    begin
        LibraryVariableStorage.Dequeue(CostLCY);
        LibraryVariableStorage.Dequeue(TotalAdjCostLCY);
        ServiceCreditMemoStatistics.CostLCY.AssertEquals(CostLCY);
        ServiceCreditMemoStatistics.TotalAdjCostLCY.AssertEquals(TotalAdjCostLCY);
    end;
#endif
    [PageHandler]
    [Scope('OnPrem')]
    procedure ServiceOrderStatisticsPageHandlerNM(var ServiceOrderStatistics: TestPage "Service Order Statistics")
    var
        CostLCY: Variant;
        TotalAdjCostLCY: Variant;
    begin
        LibraryVariableStorage.Dequeue(CostLCY);
        LibraryVariableStorage.Dequeue(TotalAdjCostLCY);
        Assert.AreNearlyEqual(
          CostLCY, ServiceOrderStatistics.OriginalCostLCY.AsDecimal(), LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(FieldValidationErr, CostLbl, CostLCY));
        Assert.AreNearlyEqual(
          TotalAdjCostLCY, ServiceOrderStatistics.AdjustedCostLCY.AsDecimal(), LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(FieldValidationErr, CostLbl, TotalAdjCostLCY));
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PostedServiceInvoiceStatisticsPageHandlerNM(var ServiceInvoiceStatistics: TestPage "Service Invoice Statistics")
    var
        CostLCY: Variant;
        TotalAdjCostLCY: Variant;
    begin
        LibraryVariableStorage.Dequeue(CostLCY);
        LibraryVariableStorage.Dequeue(TotalAdjCostLCY);
        Assert.AreNearlyEqual(
          CostLCY, ServiceInvoiceStatistics.CostLCY.AsDecimal(), LibraryERM.GetAmountRoundingPrecision(), StrSubstNo(FieldValidationErr, CostLbl, CostLCY));
        Assert.AreNearlyEqual(
          TotalAdjCostLCY, ServiceInvoiceStatistics.TotalAdjCostLCY.AsDecimal(), LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(FieldValidationErr, CostLbl, TotalAdjCostLCY));
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PostedServiceCreditMemoStatisticsPageHandlerNM(var ServiceCreditMemoStatistics: TestPage "Service Credit Memo Statistics")
    var
        CostLCY: Variant;
        TotalAdjCostLCY: Variant;
    begin
        LibraryVariableStorage.Dequeue(CostLCY);
        LibraryVariableStorage.Dequeue(TotalAdjCostLCY);
        ServiceCreditMemoStatistics.CostLCY.AssertEquals(CostLCY);
        ServiceCreditMemoStatistics.TotalAdjCostLCY.AssertEquals(TotalAdjCostLCY);
    end;
}
