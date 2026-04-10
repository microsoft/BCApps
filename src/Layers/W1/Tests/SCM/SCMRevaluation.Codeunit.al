codeunit 137010 "SCM Revaluation"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Revaluation] [SCM]
        isInitialized := false;
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        InventoryPostingGroup: Code[20];
        isInitialized: Boolean;
        ErrorQtyMustBeEqual: Label 'ErrorQtyMustBeEqual';
        ErrorCostMustBeEqual: Label 'Cost must be Equal';
        ErrorGeneratedMustBeSame: Label 'Error Generated Must Be Same';
        UndoReceiptErrorMessage: Label 'You cannot undo line %1, because a revaluation has already been posted.';
        ReturnReceiptAlreadyReversedErr: Label 'This return receipt has already been reversed.';
        DimensionValueErr: Label 'Dimension value should be match';

    [Test]
    [Scope('OnPrem')]
    procedure RevaluePartialReceiveInvoice()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        TempPurchaseLine: Record "Purchase Line" temporary;
        SalesHeader: Record "Sales Header";
        TempSalesLine: Record "Sales Line" temporary;
        ItemJournalLine: Record "Item Journal Line";
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
        ItemNo: Code[20];
        LocationCode: Code[10];
        OldUnitCost: Decimal;
        NewUnitCost: Decimal;
    begin
        // Covers documents TFS_TC_ID 6200,6201,6202 and 6203.

        // Create required Inventory setups and Location.
        Initialize();
        LocationCode := CreateRequiredSetup();

        // Create Item and calculate standard cost.
        ItemNo := CreateItem(InventoryPostingGroup);
        Item.Get(ItemNo);
        CalculateStandardCost.CalcItem(ItemNo, false);

        // Create and Post Purchase order.
        CreatePurchaseOrder(PurchaseHeader, "Purchase Document Type"::Order, ItemNo, LocationCode, true, true);
        TransferPurchaseLineToTemp(TempPurchaseLine, PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Run Adjust cost and create Revaluation Journal.
        LibraryCosting.AdjustCostItemEntries(ItemNo, '');
        CreateRevalutionJournal(Item, ItemJournalLine);

        // Verify: Inventory To Revalue.
        VerifyInventoryToRevalue(Item."No.");

        // Execute : Post Revaluation Journal.
        OldUnitCost := Item."Standard Cost";
        NewUnitCost :=
          UpdateUnitCostToRevalue(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name", Item."No.", OldUnitCost);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        Item.Get(ItemNo);
        Item.CalcFields(Inventory);

        // Verify: Item Cost with revalued cost.
        Assert.AreEqual(Item."Standard Cost", NewUnitCost, ErrorCostMustBeEqual);

        // Create and Post sales order.
        CreateSalesDocument(SalesHeader, Item."No.", LocationCode, "Sales Document Type"::Order, Item.Inventory, false);
        TransferSalesLineToTemp(TempSalesLine, SalesHeader);
        PostSalesDocument("Sales Document Type"::Order, SalesHeader."No.", true, true, false);

        // Run Adjust cost,post remaining purchase order and post inventory cost to GL.
        LibraryCosting.AdjustCostItemEntries(ItemNo, '');
        PostOpenPurchaseOrder(PurchaseHeader);

        // Verify Value Entry.
        VerifyValueEntry(
          TempPurchaseLine, TempSalesLine, Item."No.", OldUnitCost, NewUnitCost, OldUnitCost - NewUnitCost, true, false, false, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure RevaluePurchReceiptUndoReceipt()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        TempPurchaseLine: Record "Purchase Line" temporary;
        SalesHeader: Record "Sales Header";
        TempSalesLine: Record "Sales Line" temporary;
        ItemJournalLine: Record "Item Journal Line";
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
        LocationCode: Code[10];
        ItemNo: Code[20];
        OldUnitCost: Decimal;
        NewUnitCost: Decimal;
    begin
        // Covers documents TFS_TC_ID 6165.

        // Create required Inventory setups and Location.
        Initialize();
        LocationCode := CreateRequiredSetup();

        // Create Item and calculate standard cost.
        ItemNo := CreateItem(InventoryPostingGroup);
        Item.Get(ItemNo);
        CalculateStandardCost.CalcItem(ItemNo, false);

        // Create and Post Purchase Receipt, undo receipt, Post receipt.
        CreatePurchaseOrder(PurchaseHeader, "Purchase Document Type"::Order, ItemNo, LocationCode, true, false);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        UndoPurchaseReceipt(PurchaseHeader."No.", Item."No.", false);
        UpdatePurchaseLine(PurchaseHeader."No.", Item."No.");
        TransferPurchaseLineToTemp(TempPurchaseLine, PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // Run Adjust cost and create Revaluation Journal.
        LibraryCosting.AdjustCostItemEntries(ItemNo, '');
        CreateRevalutionJournal(Item, ItemJournalLine);

        // Verify: Inventory To Revalue.
        VerifyInventoryToRevalue(Item."No.");

        // Execute : Post Revaluation Journal.
        OldUnitCost := Item."Standard Cost";
        NewUnitCost :=
          UpdateUnitCostToRevalue(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name", Item."No.", OldUnitCost);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        Item.Get(ItemNo);
        Item.CalcFields(Inventory);

        // Verify: Item Cost with revalued cost.
        Assert.AreEqual(Item."Standard Cost", NewUnitCost, ErrorCostMustBeEqual);

        // Verify: Undo Purchase Receipt Error.
        VerifyUndoPurchaseReceiptError(PurchaseHeader."No.", Item."No.");

        // Create and Post sales order.
        CreateSalesDocument(SalesHeader, Item."No.", LocationCode, "Sales Document Type"::Order, Item.Inventory, false);
        TransferSalesLineToTemp(TempSalesLine, SalesHeader);
        PostSalesDocument("Sales Document Type"::Order, SalesHeader."No.", true, true, false);

        // Run Adjust cost,post remaining purchase order and post inventory cost to GL.
        LibraryCosting.AdjustCostItemEntries(ItemNo, '');
        PostOpenPurchaseOrder(PurchaseHeader);

        // Verify Value Entry.
        VerifyValueEntry(
          TempPurchaseLine, TempSalesLine, Item."No.", OldUnitCost, NewUnitCost, OldUnitCost - NewUnitCost, false, true, false, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure RevalueSalesUndoReturnReceipt()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        TempSalesLine: Record "Sales Line" temporary;
        TempPurchaseLine: Record "Purchase Line" temporary;
        ItemJournalLine: Record "Item Journal Line";
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
        LocationCode: Code[10];
        ItemNo: Code[20];
        OldUnitCost: Decimal;
        NewUnitCost: Decimal;
    begin
        // Covers documents TFS_TC_ID 6211.

        // Create required Inventory setups and Location.
        Initialize();
        LocationCode := CreateRequiredSetup();

        // Create Item and calculate standard cost.
        ItemNo := CreateItem(InventoryPostingGroup);
        CalculateStandardCost.CalcItem(ItemNo, false);

        // Create and Post sales Return Receipt, Undo Return receipt, Update Return quantity to receive and Post it.
        CreateSalesDocument(SalesHeader, ItemNo, LocationCode, "Sales Document Type"::"Return Order", LibraryRandom.RandInt(50), true);
        PostSalesDocument("Sales Document Type"::"Return Order", SalesHeader."No.", false, false, true);
        UndoSalesReturnReceipt(SalesHeader."No.", ItemNo);
        UpdateSalesLine(SalesHeader."No.", ItemNo);
        PostSalesDocument("Sales Document Type"::"Return Order", SalesHeader."No.", false, false, true);

        // Run Adjust cost and create Revaluation Journal.
        LibraryCosting.AdjustCostItemEntries(ItemNo, '');
        Item.Get(ItemNo);
        CreateRevalutionJournal(Item, ItemJournalLine);

        // Verify: Inventory To Revalue.
        VerifyInventoryToRevalue(Item."No.");

        // Execute : Post Revaluation Journal.
        OldUnitCost := Item."Standard Cost";
        NewUnitCost :=
          UpdateUnitCostToRevalue(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name", Item."No.", OldUnitCost);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // Verify: Undo Sales Return Receipt Error.
        VerifyUndoSaleRetReceiptError(SalesHeader."No.", Item."No.");

        // Post remaing Sales Return Order,Run Adjust cost,post remaining purchase order and and post inventory cost to GL.
        TransferSalesLineToTemp(TempSalesLine, SalesHeader);
        PostSalesDocument("Sales Document Type"::"Return Order", SalesHeader."No.", false, true, false);
        LibraryCosting.AdjustCostItemEntries(ItemNo, '');

        // Verify Value Entry.
        VerifyValueEntry(
          TempPurchaseLine, TempSalesLine, Item."No.", OldUnitCost, NewUnitCost, OldUnitCost - NewUnitCost, false, false, true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RevalueSalesPurchReturn()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        TempPurchaseLine: Record "Purchase Line" temporary;
        SalesHeader: Record "Sales Header";
        TempSalesLine: Record "Sales Line" temporary;
        ItemJournalLine: Record "Item Journal Line";
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
        LocationCode: Code[10];
        ItemNo: Code[20];
        OldUnitCost: Decimal;
        NewUnitCost: Decimal;
    begin
        // Covers documents TFS_TC_ID 6212,6213,6214 and 6215.

        // Create required Inventory setups and Location.
        Initialize();
        LocationCode := CreateRequiredSetup();

        // Create Item and calculate standard cost.
        ItemNo := CreateItem(InventoryPostingGroup);
        CalculateStandardCost.CalcItem(ItemNo, false);

        // Create and Post Sales Return Receipt.
        CreateSalesDocument(SalesHeader, ItemNo, LocationCode, "Sales Document Type"::"Return Order", LibraryRandom.RandInt(50), false);
        PostSalesDocument("Sales Document Type"::"Return Order", SalesHeader."No.", false, false, true);

        // Run Adjust cost and create Revaluation Journal.
        LibraryCosting.AdjustCostItemEntries(ItemNo, '');
        Item.Get(ItemNo);
        CreateRevalutionJournal(Item, ItemJournalLine);

        // Verify Inventory To Revalue.
        VerifyInventoryToRevalue(Item."No.");

        // Execute : Post Revaluation Journal.
        OldUnitCost := Item."Standard Cost";
        NewUnitCost :=
          UpdateUnitCostToRevalue(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name", Item."No.", OldUnitCost);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        Item.Get(ItemNo);
        Item.CalcFields(Inventory);

        // Verify: Item Cost with revalued cost.
        Assert.AreEqual(Item."Standard Cost", NewUnitCost, ErrorCostMustBeEqual);

        // Create and Post Purchase Return Order.
        CreatePurchaseOrder(PurchaseHeader, "Purchase Document Type"::"Return Order", ItemNo, LocationCode, false, false);
        TransferPurchaseLineToTemp(TempPurchaseLine, PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Post remaining Sales return order,Run Adjust cost and and post inventory cost to GL.
        TransferSalesLineToTemp(TempSalesLine, SalesHeader);
        PostSalesDocument("Sales Document Type"::"Return Order", SalesHeader."No.", false, true, false);
        LibraryCosting.AdjustCostItemEntries(ItemNo, '');

        // Verify Value Entry.
        VerifyValueEntry(
          TempPurchaseLine, TempSalesLine, Item."No.", OldUnitCost, NewUnitCost,
          OldUnitCost - NewUnitCost, false, false, false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RevaluePartialPurchReceive()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        TempPurchaseLine: Record "Purchase Line" temporary;
        SalesHeader: Record "Sales Header";
        TempSalesLine: Record "Sales Line" temporary;
        ItemJournalLine: Record "Item Journal Line";
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
        LocationCode: Code[10];
        ItemNo: Code[20];
        OldUnitCost: Decimal;
        NewUnitCost: Decimal;
    begin
        // Covers documents TFS_TC_ID 6164,6166 and 6168.

        // Create required Inventory setups and Location.
        Initialize();
        LocationCode := CreateRequiredSetup();

        // Create Item and calculate standard cost.
        ItemNo := CreateItem(InventoryPostingGroup);
        Item.Get(ItemNo);
        CalculateStandardCost.CalcItem(ItemNo, false);

        // Create and Post Purchase Receipt.
        CreatePurchaseOrder(PurchaseHeader, "Purchase Document Type"::Order, ItemNo, LocationCode, false, false);
        TransferPurchaseLineToTemp(TempPurchaseLine, PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // Run Adjust cost and create Revaluation Journal.
        LibraryCosting.AdjustCostItemEntries(ItemNo, '');
        CreateRevalutionJournal(Item, ItemJournalLine);

        // Verify: Inventory To Revalue.
        VerifyInventoryToRevalue(Item."No.");

        // Execute : Post Revaluation Journal.
        OldUnitCost := Item."Standard Cost";
        NewUnitCost :=
          UpdateUnitCostToRevalue(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name", Item."No.", OldUnitCost);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        Item.Get(ItemNo);
        Item.CalcFields(Inventory);

        // Verify: Item Cost with revalued cost.
        Assert.AreEqual(Item."Standard Cost", NewUnitCost, ErrorCostMustBeEqual);

        // Create and Post sales order.
        CreateSalesDocument(SalesHeader, Item."No.", LocationCode, "Sales Document Type"::Order, Item.Inventory, false);
        TransferSalesLineToTemp(TempSalesLine, SalesHeader);
        PostSalesDocument("Sales Document Type"::Order, SalesHeader."No.", true, true, false);

        // Run Adjust cost,post remaining purchase order and and post inventory cost to GL.
        LibraryCosting.AdjustCostItemEntries(ItemNo, '');
        PostOpenPurchaseOrder(PurchaseHeader);

        // Verify Value Entry.
        VerifyValueEntry(
          TempPurchaseLine, TempSalesLine, Item."No.", OldUnitCost, NewUnitCost, OldUnitCost - NewUnitCost, false, true, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocationDefaultsDimensionsOnItemRevaluation()
    var
        DefaultDimension: Record "Default Dimension";
        Dimension: array[2] of Record Dimension;
        DimensionSetEntry: Record "Dimension Set Entry";
        DimensionValue: array[2] of Record "Dimension Value";
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        PurchaseHeader: array[2] of Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        LibraryDimension: Codeunit "Library - Dimension";
        AreaDimCode: Code[20];
        AreaDimValueCode: Code[20];
        BusinessGroupDimCode: Code[20];
        BusinessGroupDimValueCode: Code[20];
        LocationCode: Code[10];
        ItemNo: Code[20];
        i: Integer;
    begin
        // [SCENARIO 603936] Location dimensions should defaulting into Item Revaluation Journal when Calculate Inventory Value.
        Initialize();

        // [GIVEN] Create Dimensions.
        LibraryDimension.CreateDimension(Dimension[1]);
        LibraryDimension.CreateDimension(Dimension[2]);
        AreaDimCode := Dimension[1].Code;
        BusinessGroupDimCode := Dimension[2].Code;

        // [GIVEN] Create Dimension Values.
        LibraryDimension.CreateDimensionValue(DimensionValue[1], AreaDimCode);
        LibraryDimension.CreateDimensionValue(DimensionValue[2], BusinessGroupDimCode);
        AreaDimValueCode := DimensionValue[1].Code;
        BusinessGroupDimValueCode := DimensionValue[2].Code;

        // [GIVEN] Create Location with default dimensions.
        LocationCode := CreateRequiredSetup();
        LibraryDimension.CreateDefaultDimension(DefaultDimension, Database::Location, LocationCode, BusinessGroupDimCode, BusinessGroupDimValueCode);
        DefaultDimension."Value Posting" := DefaultDimension."Value Posting"::"Code Mandatory";
        DefaultDimension.Modify();

        // [GIVEN] Create Item with default dimensions.
        ItemNo := CreateItem(InventoryPostingGroup);
        Item.Get(ItemNo);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, Database::Item, ItemNo, AreaDimCode, AreaDimValueCode);
        DefaultDimension."Value Posting" := DefaultDimension."Value Posting"::"Code Mandatory";
        DefaultDimension.Modify();

        // [GIVEN] Create and post Purchase Order.
        for i := 1 to 2 do begin
            CreatePurchaseOrder(PurchaseHeader[i], PurchaseHeader[i]."Document Type"::Order, ItemNo, LocationCode, false, false);
            LibraryPurchase.PostPurchaseDocument(PurchaseHeader[i], true, true);
        end;

        // [GIVEN] Create and post Sales Order.
        CreateSalesDocument(SalesHeader, ItemNo, LocationCode, "Sales Document Type"::Order, LibraryRandom.RandInt(50), false);
        PostSalesDocument("Sales Document Type"::Order, SalesHeader."No.", true, true, false);

        // [WHEN] Run Calculate Inventory Value with Calculate Per: Item and By Location.
        CreateRevalutionJournalByLocation(Item, ItemJournalLine, LocationCode);

        ItemJournalLine.SetRange("Item No.", Item."No.");
        ItemJournalLine.SetRange("Location Code", LocationCode);
        ItemJournalLine.FindFirst();

        // [THEN] Verify Item dimension (AREA) is present.
        DimensionSetEntry.SetRange("Dimension Set ID", ItemJournalLine."Dimension Set ID");
        DimensionSetEntry.SetRange("Dimension Code", AreaDimCode);
        DimensionSetEntry.FindFirst();
        Assert.AreEqual(AreaDimValueCode, DimensionSetEntry."Dimension Value Code", DimensionValueErr);

        // [THEN] Verify Location dimension (BUSINESSGROUP) is present.
        DimensionSetEntry.SetRange("Dimension Code", BusinessGroupDimCode);
        DimensionSetEntry.FindFirst();
        Assert.AreEqual(BusinessGroupDimValueCode, DimensionSetEntry."Dimension Value Code", DimensionValueErr);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Revaluation");
        // Lazy Setup.
        LibrarySetupStorage.Restore();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Revaluation");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        isInitialized := true;
        Commit();

        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Revaluation");
    end;

    [Normal]
    local procedure CreateRequiredSetup(): Code[10]
    var
        Location: Record Location;
        InventoryPostingGroupRec: Record "Inventory Posting Group";
    begin
        LibraryInventory.SetAutomaticCostPosting(true);
        LibraryInventory.SetExpectedCostPosting(false);
        LibraryInventory.SetAutomaticCostAdjmtNever();
        LibraryInventory.SetAverageCostSetup("Average Cost Calculation Type"::Item, "Average Cost Period Type"::Day);

        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        InventoryPostingGroupRec.FindFirst();
        InventoryPostingGroup := InventoryPostingGroupRec.Code;
        exit(Location.Code);
    end;

    [Normal]
    local procedure CreateItem(InventoryPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);

        Item.Validate("Inventory Posting Group", InventoryPostingGroup);
        Item.Validate("Costing Method", Item."Costing Method"::Standard);
        Item.Validate("Standard Cost", LibraryRandom.RandInt(50));
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; ItemNo: Code[20]; LocationCode: Code[20]; PartialReceive: Boolean; PartialReceiveInvoice: Boolean)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, '');
        if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::Order then
            PurchaseHeader.Validate(
              "Vendor Invoice No.",
              LibraryUtility.GenerateRandomCode(PurchaseHeader.FieldNo("Vendor Invoice No."), DATABASE::"Purchase Header"));
        if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::"Return Order" then
            PurchaseHeader.Validate(
              "Vendor Cr. Memo No.",
              LibraryUtility.GenerateRandomCode(PurchaseHeader.FieldNo("Vendor Cr. Memo No."), DATABASE::"Purchase Header"));
        PurchaseHeader.Validate("Location Code", LocationCode);
        PurchaseHeader.Modify(true);
        CreatePurchaseLine(PurchaseHeader, ItemNo, PartialReceive, PartialReceiveInvoice);
    end;

    local procedure CreatePurchaseLine(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; PartialReceive: Boolean; PartialInvoice: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Create Purchase Line with Partial quantity to receive and invoice,Values used are important for test.
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandInt(50) + 50);
        if PartialReceive then
            PurchaseLine.Validate("Qty. to Receive", PurchaseLine.Quantity - 10);
        if PartialInvoice then
            PurchaseLine.Validate("Qty. to Invoice", PurchaseLine."Qty. to Receive" - 10);
        PurchaseLine.Modify();
    end;

    [Normal]
    local procedure UndoPurchaseReceipt(PurchaseOrderNo: Code[20]; ItemNo: Code[20]; IsCostRevalued: Boolean)
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        PurchRcptHeader.SetRange("Order No.", PurchaseOrderNo);
        if IsCostRevalued then
            PurchRcptHeader.FindLast()
        else
            PurchRcptHeader.FindFirst();
        PurchRcptLine.SetRange("Document No.", PurchRcptHeader."No.");
        PurchRcptLine.SetRange("No.", ItemNo);
        PurchRcptLine.FindFirst();
        LibraryPurchase.UndoPurchaseReceiptLine(PurchRcptLine);
    end;

    [Normal]
    local procedure UndoSalesReturnReceipt(SalesReturnOrderNo: Code[20]; ItemNo: Code[20])
    var
        ReturnReceiptHeader: Record "Return Receipt Header";
        ReturnReceiptLine: Record "Return Receipt Line";
    begin
        ReturnReceiptHeader.SetRange("Return Order No.", SalesReturnOrderNo);
        ReturnReceiptHeader.FindFirst();
        ReturnReceiptLine.SetRange("Document No.", ReturnReceiptHeader."No.");
        ReturnReceiptLine.SetRange("No.", ItemNo);
        ReturnReceiptLine.FindFirst();
        LibrarySales.UndoReturnReceiptLine(ReturnReceiptLine);
    end;

    local procedure UpdatePurchaseLine(PurchaseOrderNo: Code[20]; ItemNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document No.", PurchaseOrderNo);
        PurchaseLine.SetRange("No.", ItemNo);
        PurchaseLine.FindFirst();
        PurchaseLine.Validate("Qty. to Receive", PurchaseLine.Quantity);
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateSalesLine(SalesDocumentNo: Code[20]; ItemNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::"Return Order");
        SalesLine.SetRange("Document No.", SalesDocumentNo);
        SalesLine.SetRange("No.", ItemNo);
        SalesLine.FindFirst();
        SalesLine.Validate("Return Qty. to Receive", SalesLine.Quantity);
        SalesLine.Modify(true);
    end;

    [Normal]
    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; LocationCode: Code[20]; DocumentType: Enum "Sales Document Type"; RevaluedQuantity: Decimal; IsPartial: Boolean)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, '');
        SalesHeader.Validate("Location Code", LocationCode);
        SalesHeader.Modify(true);
        CreateSalesLine(SalesHeader, ItemNo, RevaluedQuantity, IsPartial);
    end;

    [Normal]
    local procedure CreateSalesLine(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; RevaluedQuantity: Decimal; IsPartial: Boolean)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, RevaluedQuantity);
        if IsPartial then
            SalesLine.Validate("Return Qty. to Receive", SalesLine.Quantity - 2);
        if SalesHeader."Document Type" = SalesHeader."Document Type"::"Return Order" then
            SalesLine.Validate("Qty. to Ship", 0);
        SalesLine.Modify(true);
    end;

    local procedure PostSalesDocument(DocumentType: Enum "Sales Document Type"; SalesDocumentNo: Code[20]; Ship: Boolean; Invoice: Boolean; Receive: Boolean)
    var
        SalesHeader: Record "Sales Header";
        SalesPost: Codeunit "Sales-Post";
    begin
        SalesHeader.Get(DocumentType, SalesDocumentNo);
        SalesHeader.Validate(Ship, Ship);
        SalesHeader.Validate(Invoice, Invoice);
        SalesHeader.Validate(Receive, Receive);
        SalesPost.Run(SalesHeader);
    end;

    [Normal]
    local procedure PostOpenPurchaseOrder(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.Validate(
          "Vendor Invoice No.",
          LibraryUtility.GenerateRandomCode(PurchaseHeader.FieldNo("Vendor Invoice No."), DATABASE::"Purchase Header"));
        PurchaseHeader.Modify(true);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure SelectItemJournalTemplate(): Code[10]
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        // Select Item Journal Template Name for General Journal Line.
        ItemJournalTemplate.SetRange(Type, ItemJournalTemplate.Type::Revaluation);
        if not ItemJournalTemplate.FindFirst() then begin
            ItemJournalTemplate.Init();
            ItemJournalTemplate.Validate(
              Name, CopyStr(LibraryUtility.GenerateRandomCode(ItemJournalTemplate.FieldNo(Name), DATABASE::"Item Journal Template"), 1,
                MaxStrLen(ItemJournalTemplate.Name)));
            ItemJournalTemplate.Insert(true);
        end;
        exit(ItemJournalTemplate.Name);
    end;

    local procedure CreateItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch")
    begin
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, SelectItemJournalTemplate());
        ItemJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalBatch.Modify(true);
    end;

    [Normal]
    local procedure CreateRevalutionJournal(var Item: Record Item; var ItemJournalLine: Record "Item Journal Line")
    var
        ItemJournalBatch: Record "Item Journal Batch";
        CalculateInventoryValue: Report "Calculate Inventory Value";
    begin
        CreateItemJournalBatch(ItemJournalBatch);
        ItemJournalLine.Validate("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.Validate("Journal Batch Name", ItemJournalBatch.Name);
        CalculateInventoryValue.SetParameters(
            WorkDate(), ItemJournalLine."Document No.", true, "Inventory Value Calc. Per"::Item,
            false, false, true, "Inventory Value Calc. Base"::" ", false);
        Commit();
        CalculateInventoryValue.UseRequestPage(false);
        CalculateInventoryValue.SetItemJnlLine(ItemJournalLine);
        Item.SetRange("No.", Item."No.");
        CalculateInventoryValue.SetTableView(Item);
        CalculateInventoryValue.RunModal();
    end;

    [Normal]
    local procedure UpdateUnitCostToRevalue(JournalTemplateName: Text[10]; JournalTemplateBatch: Text[10]; ItemNo: Code[20]; OldUnitCost: Decimal): Decimal
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.SetRange("Journal Template Name", JournalTemplateName);
        ItemJournalLine.SetRange("Journal Batch Name", JournalTemplateBatch);
        ItemJournalLine.SetRange("Item No.", ItemNo);
        ItemJournalLine.FindFirst();
        ItemJournalLine.Validate("Unit Cost (Revalued)", OldUnitCost + LibraryRandom.RandInt(50));
        ItemJournalLine.Modify(true);
        exit(ItemJournalLine."Unit Cost (Revalued)");
    end;

    local procedure TransferPurchaseLineToTemp(var TempPurchaseLine: Record "Purchase Line" temporary; PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();
        TempPurchaseLine := PurchaseLine;
        TempPurchaseLine.Insert();
    end;

    local procedure TransferSalesLineToTemp(var TempSalesLine: Record "Sales Line" temporary; SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        TempSalesLine := SalesLine;
        TempSalesLine.Insert();
    end;

    [Normal]
    local procedure CalcValueEntriesCostPostedToGL(ItemNo: Code[20]; FilterOnEntryType: Boolean) CostPostedGL: Decimal
    var
        ValueEntry: Record "Value Entry";
    begin
        if FilterOnEntryType then
            ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::Revaluation);
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.FindSet();
        repeat
            CostPostedGL += ValueEntry."Cost Posted to G/L";
        until ValueEntry.Next() = 0;
    end;

    [Normal]
    local procedure VerifyInventoryToRevalue(ItemNo: Code[20])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemJournalLine: Record "Item Journal Line";
        Inventory: Decimal;
    begin
        ItemLedgerEntry.SetCurrentKey("Item No.");
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindSet();
        repeat
            Inventory += ItemLedgerEntry.Quantity
        until ItemLedgerEntry.Next() = 0;

        ItemJournalLine.SetRange("Item No.", ItemNo);
        ItemJournalLine.FindFirst();

        Assert.AreEqual(Inventory, ItemJournalLine.Quantity, ErrorQtyMustBeEqual);
    end;

    [Normal]
    local procedure VerifyValueEntryRevaluation(var TempPurchaseLine: Record "Purchase Line" temporary; ItemNo: Code[20]; AdjustedRevaluationCost: Decimal; IsPartialPurchase: Boolean)
    var
        CostPostedGLRevalue: Decimal;
        CalculatedCostPostedGLRevalue: Decimal;
    begin
        CostPostedGLRevalue := CalcValueEntriesCostPostedToGL(ItemNo, true);

        if IsPartialPurchase then
            CalculatedCostPostedGLRevalue :=
              TempPurchaseLine."Qty. to Invoice" * AdjustedRevaluationCost;

        Assert.AreEqual(Abs(CalculatedCostPostedGLRevalue), Abs(CostPostedGLRevalue), ErrorCostMustBeEqual);
    end;

    [Normal]
    local procedure VerifyValueEntry(var TempPurchaseLine: Record "Purchase Line" temporary; var TempSalesLine: Record "Sales Line" temporary; ItemNo: Code[20]; CostBeforeRevaluation: Decimal; CostAfterRevaluation: Decimal; AdjustedRevaluationCost: Decimal; IsPartialPurchase: Boolean; IsPurchaseAfterRevalue: Boolean; IsSalesReturn: Boolean; IsSalesPurchaseReturn: Boolean)
    var
        CostPostedGL: Decimal;
        CalculatedCostPostedGL: Decimal;
    begin
        VerifyValueEntryRevaluation(TempPurchaseLine, ItemNo, AdjustedRevaluationCost, IsPartialPurchase);

        CostPostedGL := CalcValueEntriesCostPostedToGL(ItemNo, false);
        if IsPartialPurchase then
            CalculatedCostPostedGL :=
              TempPurchaseLine."Qty. to Invoice" * CostBeforeRevaluation -
              TempPurchaseLine."Qty. to Invoice" * AdjustedRevaluationCost -
              TempSalesLine."Qty. to Invoice" * CostAfterRevaluation;

        if IsPurchaseAfterRevalue then
            CalculatedCostPostedGL :=
              TempPurchaseLine."Qty. to Invoice" * CostAfterRevaluation -
              TempSalesLine."Qty. to Invoice" * CostAfterRevaluation;

        if IsSalesReturn then
            CalculatedCostPostedGL :=
              TempSalesLine."Qty. to Invoice" * CostAfterRevaluation;

        if IsSalesPurchaseReturn then
            CalculatedCostPostedGL :=
              TempPurchaseLine."Qty. to Invoice" * CostAfterRevaluation -
              TempSalesLine."Qty. to Invoice" * CostAfterRevaluation;

        Assert.AreEqual(Abs(CalculatedCostPostedGL), Abs(CostPostedGL), ErrorCostMustBeEqual);
    end;

    [Normal]
    local procedure VerifyUndoPurchaseReceiptError(PurchaseOrderNo: Code[20]; ItemNo: Code[20])
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        PurchRcptHeader.SetRange("Order No.", PurchaseOrderNo);
        PurchRcptHeader.FindLast();
        PurchRcptLine.SetRange("Document No.", PurchRcptHeader."No.");
        PurchRcptLine.SetRange("No.", ItemNo);
        PurchRcptLine.FindFirst();
        asserterror UndoPurchaseReceipt(PurchaseOrderNo, ItemNo, true);
        Assert.AreEqual(
          StrSubstNo(UndoReceiptErrorMessage, PurchRcptLine."Line No."), GetLastErrorText,
          ErrorGeneratedMustBeSame);
    end;

    [Normal]
    local procedure VerifyUndoSaleRetReceiptError(SalesReturnOrderNo: Code[20]; ItemNo: Code[20])
    var
        ReturnReceiptHeader: Record "Return Receipt Header";
        ReturnReceiptLine: Record "Return Receipt Line";
    begin
        ReturnReceiptHeader.SetRange("Return Order No.", SalesReturnOrderNo);
        ReturnReceiptHeader.FindFirst();
        ReturnReceiptLine.SetRange("Document No.", ReturnReceiptHeader."No.");
        ReturnReceiptLine.SetRange("No.", ItemNo);
        ReturnReceiptLine.FindFirst();
        asserterror UndoSalesReturnReceipt(SalesReturnOrderNo, ItemNo);
        Assert.AreEqual(
          ReturnReceiptAlreadyReversedErr, GetLastErrorText,
          ErrorGeneratedMustBeSame);
    end;

    local procedure CreateRevalutionJournalByLocation(var Item: Record Item; var ItemJournalLine: Record "Item Journal Line"; LocationCode: Code[10])
    var
        ItemJournalBatch: Record "Item Journal Batch";
        CalculateInventoryValue: Report "Calculate Inventory Value";
    begin
        CreateItemJournalBatch(ItemJournalBatch);
        ItemJournalLine.Validate("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.Validate("Journal Batch Name", ItemJournalBatch.Name);
        CalculateInventoryValue.SetParameters(
            WorkDate(), ItemJournalLine."Document No.", true, "Inventory Value Calc. Per"::Item,
            true, false, false, "Inventory Value Calc. Base"::" ", false); // ByLocation = true
        Commit();
        
        CalculateInventoryValue.UseRequestPage(false);
        CalculateInventoryValue.SetItemJnlLine(ItemJournalLine);
        Item.SetRange("No.", Item."No.");
        Item.SetRange("Location Filter", LocationCode); // Filter to specific location
        CalculateInventoryValue.SetTableView(Item);
        CalculateInventoryValue.RunModal();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(ConfirmText: Text[1024]; var Confirm: Boolean)
    begin
        Confirm := true;
    end;
}

