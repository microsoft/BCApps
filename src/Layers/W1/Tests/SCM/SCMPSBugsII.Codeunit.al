codeunit 137036 "SCM PS Bugs - II"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SCM]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryDimension: Codeunit "Library - Dimension";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        isInitialized: Boolean;
        UnexpectedOrderLineDimValueErr: Label 'Unexpected dimension value on the production order line.';
        DeletePickedLinesQst: Label 'Components for production order %1 have already been picked. Do you want to continue?',
            Comment = '%1 = Production order no.: Components for production order 101001 have already been picked. Do you want to continue?';
        CircularReferenceErr: Label 'The production BOM %1 has a circular reference', Comment = '%1: Production BOM No.';
        ProdBOMMustBeCertifiedErr: Label 'Production BOM must be certified';

    [Test]
    [Scope('OnPrem')]
    procedure RequisitionWorksheetBatch()
    var
        Item: Record Item;
        RequisitionWkshName: Record "Requisition Wksh. Name";
        SalesHeader: Record "Sales Header";
        SalesOrderNo: Code[20];
        SalesOrderNo2: Code[20];
        ReqWorksheetName: Code[10];
        ReqWorksheetName2: Code[10];
    begin
        // Setup: Create two Sales Orders with different Item lines.
        Initialize();
        LibrarySales.SetCreditWarningsToNoWarnings();
        LibrarySales.SetStockoutWarning(false);

        SalesOrderNo :=
          CreateSalesDocumentSetup(
            Item."Replenishment System"::Purchase, SalesHeader."Document Type"::Order);
        SalesOrderNo2 :=
          CreateSalesDocumentSetup(
            Item."Replenishment System"::Purchase, SalesHeader."Document Type"::Order);

        // Exercise: Create Requisition Lines through Drop Shipment - Get Sales Order.
        // Create Requisition Line with First Requisition Batch Name.
        CreateRequisitionWorksheetName(RequisitionWkshName);
        ReqWorksheetName := RequisitionWkshName.Name;
        CreateReqLineDropShipment(RequisitionWkshName, SalesOrderNo);

        // Create Requisition Line with Second Requisition Batch Name.
        CreateRequisitionWorksheetName(RequisitionWkshName);
        ReqWorksheetName2 := RequisitionWkshName.Name;
        CreateReqLineDropShipment(RequisitionWkshName, SalesOrderNo2);

        // Verify: Verification of Requisition line contained in each Batch.
        VerifyNewBatchRequisitionLine(ReqWorksheetName, SalesOrderNo);
        VerifyNewBatchRequisitionLine(ReqWorksheetName2, SalesOrderNo2);
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesBlanketOrderQtyShipped()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        BlanketOrderNo: Code[20];
    begin
        // Setup: Create Sales Blanket Order and Make Order.
        Initialize();
        LibrarySales.SetCreditWarningsToNoWarnings();
        LibrarySales.SetStockoutWarning(false);

        BlanketOrderNo :=
          CreateSalesDocumentSetup(
            Item."Replenishment System"::Purchase, SalesHeader."Document Type"::"Blanket Order");
        CreateSalesOrderFromBlanket(BlanketOrderNo);

        // Update Sales Lines with Drop Shipment.
        SalesLine.SetRange("Blanket Order No.", BlanketOrderNo);
        SalesLine.FindFirst();
        LibraryInventory.UpdateSalesLine(SalesLine, SalesLine.FieldNo("Drop Shipment"), true);

        // Create Purchase Order from Drop Shipment - Get Sales Order.
        CreatePurchOrderDropShipment(PurchaseHeader, SalesLine);

        // Exercise: Post Purchase Order as Receive and Sales Order as Invoice.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        SalesHeader.Get(SalesHeader."Document Type"::Order, SalesLine."Document No.");
        LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // Verify: Verification of Blanket Sales Order for Quantity Shipped.
        VerifySalesBlanketOrder(BlanketOrderNo, PurchaseHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemLedgerItemCategoryCode()
    var
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        ItemNo: Code[20];
    begin
        Initialize();

        // Setup.
        ItemNo := DropShipmentPrepare(PurchaseHeader, SalesHeader);

        // Exercise.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // Verify.
        VerifyItemCategoryCode(ItemNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProdOrderLinesDimension()
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        ItemNo: Code[20];
        ChildItemNo: Code[20];
        NewDimSetId: Integer;
    begin
        Initialize();

        // Create Child Items with Default Dimensions. Create Production BOM.
        ChildItemNo := CreateItemWithDimension();
        LibraryManufacturing.CreateCertifProdBOMWithTwoComp(ProductionBOMHeader, ChildItemNo, ChildItemNo, 1);  // Value important.

        // Create Parent Item and attach Production BOM to it. Create Released Production Order and Refresh.
        // Update Dimension on Production Order.
        ItemNo := CreateItemWithProductionBOM(ProductionBOMHeader."No.");
        CreateAndRefreshRelProdOrder(ProductionOrder, ItemNo);
        NewDimSetId := UpdateProductionOrderDimension(ProductionOrder."No.", ProductionOrder."Dimension Set ID");

        // Exercise: Update Dimensions on Production Order Lines.
        UpdateProdOrderLinesDimension(ProductionOrder."No.", ProductionOrder."Dimension Set ID", NewDimSetId);

        // Verify: Verification of Production Order Lines for Updated Dimension entries.
        VerifyLineDimension(ProductionOrder."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure "ProdOrderCompDimension-B322868"()
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
        ChildItemNo: Code[20];
        ParentItemNo: Code[20];
    begin
        Initialize();

        // Setup Items with dimensions for production order
        ChildItemNo := CreateItemWithDimension();
        LibraryManufacturing.CreateCertifProdBOMWithTwoComp(ProductionBOMHeader, ChildItemNo, ChildItemNo, 1);
        ParentItemNo := CreateItemWithProductionBOM(ProductionBOMHeader."No.");
        AddDimensionToItem(ParentItemNo, true);

        // Create released production order, change dimensions and refresh
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ParentItemNo, 1);
        ProductionOrder."Dimension Set ID" := CreateNewDimSetID(ProductionOrder."Dimension Set ID");
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // Verification
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        Assert.AreEqual(ProductionOrder."Dimension Set ID", ProdOrderLine."Dimension Set ID", 'Wrong dimension in Prod. Order Line');

        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
        ProdOrderComponent.FindSet();
        repeat
            Assert.AreEqual(
              ProductionOrder."Dimension Set ID", ProdOrderComponent."Dimension Set ID", 'Wrong dimension in Prod. Order Component');
        until ProdOrderComponent.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProdOrderLineDimensionsAfterRefresh()
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ParentItemNo: Code[20];
        ChildItemNo: Code[20];
    begin
        // Verify Production Line and Component Dimesions after refreshing Production Order.

        // Setup: Setup Items with dimensions for production order
        Initialize();
        ChildItemNo := CreateItemWithDimension();
        LibraryManufacturing.CreateCertifiedProductionBOM(ProductionBOMHeader, ChildItemNo, LibraryRandom.RandInt(5));
        ParentItemNo := CreateItemWithProductionBOM(ProductionBOMHeader."No.");
        AddDimensionToItem(ParentItemNo, false);

        // Exercise: Create released Production Order.
        CreateAndRefreshRelProdOrder(ProductionOrder, ParentItemNo);

        // Verify: Verify Dimensions on Production Line and Componenets.
        VerifyLineDimension(ProductionOrder."No.");
        FindProductionOrderLine(ProdOrderLine, ProductionOrder);
        VerifyProductionOrderComponentDimension(ProductionOrder, ProdOrderLine."Dimension Set ID", ProdOrderLine."Line No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ComponentDimensionsAfterCreatingNewDimOnProdOrder()
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ParentItemNo: Code[20];
        ChildItemNo: Code[20];
    begin
        // Verify Production Line and Component Dimesions when New Dimension created on Production Order.

        // Setup: Setup Items with dimensions for production order
        Initialize();
        ChildItemNo := CreateItemWithDimension();
        LibraryManufacturing.CreateCertifProdBOMWithTwoComp(ProductionBOMHeader, ChildItemNo, ChildItemNo, 1);
        ParentItemNo := CreateItemWithProductionBOM(ProductionBOMHeader."No.");
        AddDimensionToItem(ParentItemNo, false);

        // Exercise: Create released production order, Create New dimensions and refresh
        LibraryManufacturing.CreateProductionOrder(ProductionOrder,
          ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ParentItemNo,
          LibraryRandom.RandDec(10, 2));
        UpdateProductionOrderDimensionSetId(ProductionOrder, CreateNewDimSetID(ProductionOrder."Dimension Set ID"));
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // Verify: Verify  Production Order Line and Component Dimension.
        VerifyLineDimension(ProductionOrder."No.");
        FindProductionOrderLine(ProdOrderLine, ProductionOrder);
        VerifyProductionOrderComponentDimension(ProductionOrder, ProdOrderLine."Dimension Set ID", ProdOrderLine."Line No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ComponentDimensionsAfterDeletingDimOnProdOrder()
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ParentItemNo: Code[20];
        ChildItemNo: Code[20];
    begin
        // Verify Production Order Component Dimesions when Dimension on Production Order is Deleted.

        // Setup: Setup Items with dimensions for production order
        Initialize();
        ChildItemNo := CreateItemWithDimension();
        LibraryManufacturing.CreateCertifiedProductionBOM(ProductionBOMHeader, ChildItemNo, LibraryRandom.RandInt(5));
        ParentItemNo := CreateItemWithProductionBOM(ProductionBOMHeader."No.");
        AddDimensionToItem(ParentItemNo, false);

        // Exercise: Create released Production Order,Delete dimensions and refresh.
        LibraryManufacturing.CreateProductionOrder(ProductionOrder,
          ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ParentItemNo,
          LibraryRandom.RandDec(10, 2));
        UpdateProductionOrderDimensionSetId(ProductionOrder, 0);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // Verify: Verify Production Order Component Dimesions.
        FindProductionOrderLine(ProdOrderLine, ProductionOrder);
        VerifyProductionOrderComponentDimension(ProductionOrder, ProdOrderLine."Dimension Set ID", ProdOrderLine."Line No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ComponentDimensionsAfterDeletingDimOnProdLines()
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ParentItemNo: Code[20];
        ChildItemNo: Code[20];
    begin
        // Verify Production Order Component Dimesions when Production Order Line Dimension is Deleted.

        // Setup: Setup Items with dimensions for production order.
        Initialize();
        ChildItemNo := CreateItemWithDimension();
        LibraryManufacturing.CreateCertifProdBOMWithTwoComp(ProductionBOMHeader, ChildItemNo, ChildItemNo, 1);
        ParentItemNo := CreateItemWithProductionBOM(ProductionBOMHeader."No.");
        AddDimensionToItem(ParentItemNo, false);
        CreateAndRefreshRelProdOrder(ProductionOrder, ParentItemNo);

        // Exercise: Validate Dimension Set Id on Prod. Order Line.
        FindProductionOrderLine(ProdOrderLine, ProductionOrder);
        ProdOrderLine.Validate("Dimension Set ID", 0);
        ProdOrderLine.Modify(true);

        // Verify: Verify Production Order Component Dimensions.
        VerifyProductionOrderComponentDimension(ProductionOrder, ProductionOrder."Dimension Set ID", ProdOrderLine."Line No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostDropShptPurchOrderForSalesOrderInvoicedTwice()
    var
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        ItemNo: Code[20];
    begin
        // Setup.
        Initialize();
        ItemNo := DropShipmentPrepare(PurchaseHeader, SalesHeader);

        ModifyForPartialInvoice(SalesHeader);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify();

        // Exercise.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify.
        VerifyItemCategoryCode(ItemNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ProdOrderRefreshedAfterConfirmationWhenComponentsArePicked()
    var
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        // [FEATURE] [Manufacturing] [Refresh Production Order] [Pick]
        // [SCENARIO 364487] User receives a confirmation request when refreshing a production order with picked components. On 'Yes' answer prod. order is refreshed
        Initialize();

        // [GIVEN] Create and refresh a production order
        CreateAndRefreshProdOrderWithTwoComponents(ProductionOrder, 1, 1);

        // [GIVEN] Pick components for the production order
        // Mock components picking
        SetQuantityPickedOnProdOrderComponent(ProductionOrder.Status, ProductionOrder."No.", LibraryRandom.RandInt(10));

        // [GIVEN] Set quantity in the production order header to "X"
        ProductionOrder.Validate(Quantity, LibraryRandom.RandIntInRange(5, 10));
        ProductionOrder.Modify(false);

        // [WHEN] Refresh production order
        // [THEN] Confirmation request is shown
        // [WHEN] Accept the confirmation request
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, false, true, false);

        // [THEN] Quantity in the production order line is "X"
        FindProductionOrderLine(ProdOrderLine, ProductionOrder);
        ProdOrderLine.TestField(Quantity, ProductionOrder.Quantity);
        // [THEN] "Picked Qty." in the component line is 0
        VerifyProductionOrderComponentPickedQuantity(ProductionOrder.Status, ProductionOrder."No.", 0);
    end;

    [Test]
    [HandlerFunctions('RefreshPickedConfirmHandler')]
    [Scope('OnPrem')]
    procedure ProdOrderNotRefreshedAfterConfirmationCancelledWhenComponentsArePicked()
    var
        ProductionOrder: Record "Production Order";
        PickedQty: Integer;
    begin
        // [FEATURE] [Manufacturing] [Refresh Production Order] [Pick]
        // [SCENARIO 364487] User receives a confirmation request when refreshing a production order with picked components. On 'No' answer "Qty. Picked" is not changed
        Initialize();

        // [GIVEN] Create and refresh a production order
        CreateAndRefreshProdOrderWithTwoComponents(ProductionOrder, 1, 1);

        // [GIVEN] Pick "X" components for the production order
        // Mock components picking
        PickedQty := LibraryRandom.RandInt(10);
        SetQuantityPickedOnProdOrderComponent(ProductionOrder.Status, ProductionOrder."No.", PickedQty);

        // [WHEN] Refresh production order
        // [THEN] Confirmation request is shown
        // [WHEN] Cancel the action
        LibraryVariableStorage.Enqueue(ProductionOrder."No.");
        LibraryVariableStorage.Enqueue(false);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, false, true, false);

        // [THEN] "Qty. Picked" in the components lines is "X"
        VerifyProductionOrderComponentPickedQuantity(ProductionOrder.Status, ProductionOrder."No.", PickedQty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoConfirmationRequestIfProdOrderRefreshedWithoutRecalcLinesAndComponentsArePicked()
    var
        ProductionOrder: Record "Production Order";
        PickedQty: Integer;
    begin
        // [FEATURE] [Manufacturing] [Refresh Production Order] [Pick]
        // [SCENARIO 364487] Confirmation request should not be shown when refreshing a production order with picked component if "Calculate Lines" option is not selected
        Initialize();

        // [GIVEN] Create and refresh a production order
        CreateAndRefreshProdOrderWithTwoComponents(ProductionOrder, 1, 1);

        // [GIVEN] Pick "X" components for the production order
        // Mock components picking
        PickedQty := LibraryRandom.RandInt(10);
        SetQuantityPickedOnProdOrderComponent(ProductionOrder.Status, ProductionOrder."No.", PickedQty);

        // [WHEN] Refresh production order without "Calculate Lines" option
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, false, false, false, false);

        // [THEN] "Qty. Picked" in the components lines is "X"
        VerifyProductionOrderComponentPickedQuantity(ProductionOrder.Status, ProductionOrder."No.", PickedQty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RequisitionWorksheetDropShipmentProdItem()
    var
        Item: Record Item;
        RequisitionWkshName: Record "Requisition Wksh. Name";
        SalesHeader: Record "Sales Header";
        SalesOrderNo: Code[20];
        ReqWorksheetName: Code[10];
    begin
        // [FEATURE] [Replenishment Prod. Order] [Drop Shipment] [Requisition Worksheet]
        // [SCENARIO] Requisition Worksheet can process drop shipment Sales Order even if Item Replenishment System = "Prod. Order".
        Initialize();

        // [GIVEN] Drop Shipment Sales Order with Item "I" ("Replenishment System" = "Prod. Order") of Quantity = "Q".
        SalesOrderNo :=
          CreateSalesDocumentSetup(
            Item."Replenishment System"::"Prod. Order", SalesHeader."Document Type"::Order);

        // [WHEN] "Get Sales Orders" in Requisition Worksheet.
        CreateRequisitionWorksheetName(RequisitionWkshName);
        ReqWorksheetName := RequisitionWkshName.Name;
        CreateReqLineDropShipment(RequisitionWkshName, SalesOrderNo);

        // [THEN] Requisition line created with "I" and "Q"
        VerifyNewBatchRequisitionLine(ReqWorksheetName, SalesOrderNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultiLevelProdOrderStructureDeletedWhenDeletingSingleDemand()
    var
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemNo: array[5] of Code[20];
        I: Integer;
    begin
        // [FEATURE] [Production Order] [Make-to-Order] [Production BOM]
        // [SCENARIO 201734] When deleting a production order line that includes the same component in different positions, lines on lower planning levels should also be deleted

        Initialize();

        // [GIVEN] All items are created with "Make-to-Order" manufacturing policy
        // [GIVEN] Item "I1" is a component of a production BOM for item "I2", "I2" - component of "I3"
        ItemNo[1] := LibraryInventory.CreateItemNo();
        ItemNo[2] := CreateItemWithCertifiedProdBOM(ItemNo[1], 1);
        ItemNo[3] := CreateItemWithCertifiedProdBOM(ItemNo[2], 1);

        // [GIVEN] Item "I4" is included in a production BOM for item "I4" in 2 positions. There are 2 production BOM lines with the same item.
        Item.Get(ItemNo[3]);
        CreateProductionBOMWithComponentInTwoPositions(ProductionBOMHeader, Item."Base Unit of Measure", ItemNo[3], 1);
        ItemNo[4] := CreateItemWithProductionBOM(ProductionBOMHeader."No.");

        // [GIVEN] Item "I4" is a component of the top-level item "I5"
        LibraryManufacturing.CreateCertifiedProductionBOM(ProductionBOMHeader, ItemNo[4], 1);
        ItemNo[5] := CreateItemWithProductionBOM(ProductionBOMHeader."No.");

        // [GIVEN] Create and refresh a production order for item "I5". Multi-level production order is created with lines for items from "I5" to "I2"
        CreateAndRefreshRelProdOrder(ProductionOrder, ItemNo[5]);

        // [WHEN] Delete production order line with item "I4"
        DeleteProdOrderLineWithItem(ProductionOrder."No.", ItemNo[4]);

        // [THEN] Order lines for items "I3" and "I2" are also deleted. Only the top-level item "I5" remains.
        ProdOrderLine.SetRange("Item No.", ItemNo[5]);
        Assert.RecordCount(ProdOrderLine, 1);

        ProdOrderLine.Init();
        for I := 1 to ArrayLen(ItemNo) - 1 do begin
            ProdOrderLine.SetRange("Item No.", ItemNo[I]);
            Assert.RecordIsEmpty(ProdOrderLine);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultiLevelProdOrderStructureNotDeletedWhenDemandRemains()
    var
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemNo: array[5] of Code[20];
    begin
        // [FEATURE] [Production Order] [Make-to-Order] [Production BOM]
        // [SCENARIO 201734] When deleting a production order line that includes the same component in different positions, line for the lower-level component is not deleted is the component is included in other BOM's

        Initialize();

        // [GIVEN] All items are created with "Make-to-Order" manufacturing policy
        // [GIVEN] Item "I1" is a component of a production BOM for item "I2", "I2" - component of "I3"
        ItemNo[1] := LibraryInventory.CreateItemNo();
        ItemNo[2] := CreateItemWithCertifiedProdBOM(ItemNo[1], 1);
        ItemNo[3] := CreateItemWithCertifiedProdBOM(ItemNo[2], 1);

        // [GIVEN] Item "I4" is included in a production BOM for item "I4" in 2 positions. There are 2 production BOM lines with the same item.
        Item.Get(ItemNo[3]);
        CreateProductionBOMWithComponentInTwoPositions(ProductionBOMHeader, Item."Base Unit of Measure", ItemNo[3], 1);
        ItemNo[4] := CreateItemWithProductionBOM(ProductionBOMHeader."No.");

        // [GIVEN] Top-level component item "I5" includes two items: "I3" and "I4".
        LibraryManufacturing.CreateCertifProdBOMWithTwoComp(ProductionBOMHeader, ItemNo[3], ItemNo[4], 1);
        ItemNo[5] := CreateItemWithProductionBOM(ProductionBOMHeader."No.");

        // [GIVEN] Create and refresh a production order for item "I5". Multi-level production order is created with lines for items from "I5" to "I2"
        CreateAndRefreshRelProdOrder(ProductionOrder, ItemNo[5]);

        // [WHEN] Delete production order line with item "I4"
        DeleteProdOrderLineWithItem(ProductionOrder."No.", ItemNo[4]);

        // [THEN] Order line for items "I3" is not deleted, since "I3" is also a component of "I5".
        // [THEN] Quantity in the prod. order line for the item "I3" is updated. New quantity is 1.
        ProdOrderLine.SetRange("Item No.", ItemNo[3]);
        ProdOrderLine.FindFirst();
        ProdOrderLine.TestField(Quantity, 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    procedure CertifyBOMWithCyclicalReferenceError()
    var
        ProductionBOMHeader: array[2] of Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ManufacturingItem: Record Item;
        ComponentItem: array[2] of Record Item;
    begin
        // [FEATURE] [Production BOM]
        // [SCENARIO] Certification of a production BOM fails with an error if it contains a cyclic reference 

        Initialize();

        // [GIVEN] Set "Dynamic Low-Level Code" in Manufacturing Setup to false
        SetDynamicLowLevelCode(false);

        // [GIVEN] Top level production item "PI" and two components "CI1" and "CI2"
        LibraryInventory.CreateItem(ManufacturingItem);
        LibraryInventory.CreateItem(ComponentItem[1]);
        LibraryInventory.CreateItem(ComponentItem[2]);

        // [GIVEN] Create a production BOM "BOM1" with two lines. Line type is "Item" in both, component items are "CI1" and "CI2"
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader[1], ManufacturingItem."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
            ProductionBOMHeader[1], ProductionBOMLine, '', Enum::"Production BOM Line Type"::Item, ComponentItem[1]."No.", 1);
        LibraryManufacturing.CreateProductionBOMLine(
            ProductionBOMHeader[1], ProductionBOMLine, '', Enum::"Production BOM Line Type"::Item, ComponentItem[2]."No.", 1);

        // [GIVEN] Assign the "BOM1" to the production item "PI"
        AssignItemProductionBOM(ManufacturingItem, ProductionBOMHeader[1]."No.");

        // [GIVEN] Create a production BOM "BOM2" with the item "PI" as a component and assign this BOM to the item "CI2"
        CreateProductionBOMWithOneLine(ProductionBOMHeader[2], ComponentItem[2]."Base Unit of Measure", ManufacturingItem."No.");
        AssignItemProductionBOM(ComponentItem[2], ProductionBOMheader[2]."No.");

        // [GIVEN] Change the status of "BOM2" to "Certified"
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader[2], Enum::"BOM Status"::Certified);

        // [WHEN] Try to change the status of "BOM1" to "Certified"
        asserterror LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader[1], Enum::"BOM Status"::Certified);

        // [THEN] Error message: Production BOM has a circular reference
        Assert.ExpectedError(StrSubstNo(CircularReferenceErr, ProductionBOMHeader[1]."No."));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    procedure CertifyBOMWithCyclicalReferenceChildBOMHasActiveVersion()
    var
        ProductionBOMHeader: array[2] of Record "Production BOM Header";
        ManufacturingItem: Record Item;
        ComponentItem: array[2] of Record Item;
    begin
        // [FEATURE] [Production BOM] [BOM Version]
        // [SCENARIO] Certification of a production BOM fails with an error if its active version contains a cyclic reference 

        Initialize();

        // [GIVEN] Set "Dynamic Low-Level Code" in Manufacturing Setup to false
        SetDynamicLowLevelCode(false);

        // [GIVEN] Top level production item "PI" and two components "CI1" and "CI2"
        LibraryInventory.CreateItem(ManufacturingItem);
        LibraryInventory.CreateItem(ComponentItem[1]);
        LibraryInventory.CreateItem(ComponentItem[2]);

        // [GIVEN] Create a production BOM "BOM1" with the item "CI1" as a component and assign this BOM to the item "PI"
        CreateProductionBOMWithOneLine(ProductionBOMHeader[1], ManufacturingItem."Base Unit of Measure", ComponentItem[1]."No.");
        AssignItemProductionBOM(ManufacturingItem, ProductionBOMHeader[1]."No.");

        // [GIVEN] Create a production BOM "BOM2" with the item "CI2" as a component and assign it to the item "CI1"
        CreateProductionBOMWithOneLine(ProductionBOMHeader[2], ManufacturingItem."Base Unit of Measure", ComponentItem[2]."No.");
        AssignItemProductionBOM(ComponentItem[1], ProductionBOMHeader[2]."No.");

        // [GIVEN] Create a version of "BOM2" with one component "PI", version is active on the work date
        CreateProductionBOMVersion(ProductionBOMHeader[2], ComponentItem[1]."Base Unit of Measure", WorkDate(), ManufacturingItem."No.");

        // [GIVEN] Change the status of "BOM2" to "Certified"
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader[2], Enum::"BOM Status"::Certified);

        // [GIVEN] Try to change the status of "BOM1" to "Certified"
        asserterror LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader[1], Enum::"BOM Status"::Certified);

        // [THEN] Error message: Production BOM has a circular reference
        Assert.ExpectedError(StrSubstNo(CircularReferenceErr, ProductionBOMHeader[1]."No."));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    procedure CertifyBOMInactiveVersionWithCyclicalReference()
    var
        ProductionBOMHeader: array[2] of Record "Production BOM Header";
        ManufacturingItem: Record Item;
        ComponentItem: array[3] of Record Item;
    begin
        // [FEATURE] [Production BOM] [BOM Version]
        // [SCENARIO] Production BOM can be certified if its inactive version has a cyclic reference, but the active version is correct

        Initialize();

        // [GIVEN] Set "Dynamic Low-Level Code" in Manufacturing Setup to false
        SetDynamicLowLevelCode(false);

        // [GIVEN] Top level production item "PI" and three components "CI1", "CI2", "CI3"
        LibraryInventory.CreateItem(ManufacturingItem);
        LibraryInventory.CreateItem(ComponentItem[1]);
        LibraryInventory.CreateItem(ComponentItem[2]);
        LibraryInventory.CreateItem(ComponentItem[3]);

        // [GIVEN] Create a production BOM "BOM1" with the item "CI1" as a component and assign this BOM to the item "PI"
        CreateProductionBOMWithOneLine(ProductionBOMHeader[1], ManufacturingItem."Base Unit of Measure", ComponentItem[1]."No.");
        AssignItemProductionBOM(ManufacturingItem, ProductionBOMHeader[1]."No.");

        // [GIVEN] Create a production BOM "BOM2" with the item "CI2" as a component and assign this BOM to the item "CI1"
        CreateProductionBOMWithOneLine(ProductionBOMHeader[2], ManufacturingItem."Base Unit of Measure", ComponentItem[2]."No.");
        AssignItemProductionBOM(ComponentItem[1], ProductionBOMHeader[2]."No.");

        // [GIVEN] Create a version of "BOM2" with "PI" as a component, version is active on a previous date (WorkDate() - 1)
        CreateProductionBOMVersion(ProductionBOMHeader[2], ComponentItem[1]."Base Unit of Measure", WorkDate() - 1, ManufacturingItem."No.");

        // [GIVEN] Create a version of "BOM2" with "CI3" as a component, version is active on the current date
        CreateProductionBOMVersion(ProductionBOMHeader[2], ComponentItem[1]."Base Unit of Measure", WorkDate(), ComponentItem[3]."No.");

        // [GIVEN] Certify both production BOMs "BOM2" and "BOM1"
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader[2], Enum::"BOM Status"::Certified);
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader[1], Enum::"BOM Status"::Certified);

        // [THEN] Both production BOMs are certified without errors
        Assert.AreEqual(Enum::"BOM Status"::Certified, ProductionBOMHeader[1].Status, ProdBOMMustBeCertifiedErr);
        Assert.AreEqual(Enum::"BOM Status"::Certified, ProductionBOMHeader[2].Status, ProdBOMMustBeCertifiedErr);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"SCM PS Bugs - II");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"SCM PS Bugs - II");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibrarySetupStorage.Save(Database::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(Database::"Manufacturing Setup");

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"SCM PS Bugs - II");
    end;

    local procedure AssignItemProductionBOM(var Item: Record Item; ProductionBOMNo: Code[20])
    begin
        Item.Validate("Production BOM No.", ProductionBOMNo);
        Item.Modify(true);
    end;

    local procedure CreateAndRefreshProdOrderWithTwoComponents(var ProductionOrder: Record "Production Order"; ComponentQtyPer: Decimal; Quantity: Decimal)
    var
        ChildItem1: Record Item;
        ChildItem2: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ParentItemNo: Code[20];
    begin
        LibraryInventory.CreateItem(ChildItem1);
        LibraryInventory.CreateItem(ChildItem2);
        LibraryManufacturing.CreateCertifProdBOMWithTwoComp(
          ProductionBOMHeader, ChildItem1."No.", ChildItem2."No.", ComponentQtyPer);
        ParentItemNo := CreateItemWithProductionBOM(ProductionBOMHeader."No.");
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ParentItemNo, Quantity);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, false, true, false);
    end;

    local procedure CreateSalesDocumentSetup(ItemReplenishmentSystem: Enum "Replenishment System"; DocumentType: Enum "Sales Document Type"): Code[20]
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", ItemReplenishmentSystem);
        Item.Modify(true);
        CreateSalesDocument(SalesHeader, SalesLine, DocumentType, Item."No.");
        if DocumentType = SalesHeader."Document Type"::Order then
            LibraryInventory.UpdateSalesLine(SalesLine, SalesLine.FieldNo("Drop Shipment"), true);
        exit(SalesHeader."No.");
    end;

    local procedure DeleteProdOrderLineWithItem(ProdOrderNo: Code[20]; ItemNo: Code[20])
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderLine.SetRange("Item No.", ItemNo);
        ProdOrderLine.FindFirst();
        ProdOrderLine.Delete(true);
    end;

    local procedure DropShipmentPrepare(var PurchaseHeader: Record "Purchase Header"; var SalesHeader: Record "Sales Header") ItemNo: Code[20]
    var
        SalesLine: Record "Sales Line";
        Purchasing: Record Purchasing;
    begin
        // Setup: Create Item with New Category Code and create Sales Order with Drop Shipment.
        Initialize();
        LibrarySales.SetCreditWarningsToNoWarnings();
        LibrarySales.SetStockoutWarning(false);

        ItemNo := CreateItemWithCategory();
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, ItemNo);

        // Update Sales Lines with Purchasing Code for Drop Shipment.
        Purchasing.SetRange("Drop Shipment", true);
        Purchasing.FindFirst();
        LibraryInventory.UpdateSalesLine(SalesLine, SalesLine.FieldNo("Purchasing Code"), Purchasing.Code);

        // Create Purchase Order from Drop Shipment - Get Sales Order.
        CreatePurchOrderDropShipment(PurchaseHeader, SalesLine);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; ItemNo: Code[20])
    begin
        // Random Values not important.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, DocumentType, '', ItemNo, LibraryRandom.RandInt(10), '', 0D);
    end;

    local procedure CreateRequisitionWorksheetName(var RequisitionWkshName: Record "Requisition Wksh. Name")
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        ReqWkshTemplate.SetRange(Type, ReqWkshTemplate.Type::"Req.");
        ReqWkshTemplate.FindFirst();
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
    end;

    local procedure CreateReqLineDropShipment(RequisitionWkshName: Record "Requisition Wksh. Name"; No: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.Init();
        RequisitionLine.Validate("Worksheet Template Name", RequisitionWkshName."Worksheet Template Name");
        RequisitionLine.Validate("Journal Batch Name", RequisitionWkshName.Name);
        GetSalesOrder(RequisitionLine, No);
    end;

    local procedure GetSalesOrder(RequisitionLine: Record "Requisition Line"; DocumentNo: Code[20])
    var
        SalesLine: Record "Sales Line";
        GetSalesOrders: Report "Get Sales Orders";
        NewRetrieveDimensionsFrom: Option Item,"Sales Line";
    begin
        // Execute Get Sales Order report to populate Requisition line.
        FindSalesLine(SalesLine, SalesLine."Document Type"::Order, DocumentNo);
        GetSalesOrders.SetReqWkshLine(RequisitionLine, 0);
        GetSalesOrders.SetTableView(SalesLine);
        GetSalesOrders.InitializeRequest(NewRetrieveDimensionsFrom::Item);
        GetSalesOrders.UseRequestPage(false);
        GetSalesOrders.Run();
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20])
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.FindFirst();
    end;

    local procedure CreateSalesOrderFromBlanket(No: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::"Blanket Order");
        SalesHeader.SetRange("No.", No);
        SalesHeader.FindFirst();
        CODEUNIT.Run(CODEUNIT::"Blnkt Sales Ord. to Ord. (Y/N)", SalesHeader);
    end;

    local procedure CreateProductionBOMLineInSpecifiedPosition(var ProductionBOMHeader: Record "Production BOM Header"; var ProductionBOMLine: Record "Production BOM Line"; ItemNo: Code[20]; QuantityPer: Decimal; ItemPosition: Code[10])
    begin
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ItemNo, QuantityPer);
        ProductionBOMLine.Validate(Position, ItemPosition);
        ProductionBOMLine.Modify(true);
    end;

    local procedure CreateProductionBOMVersion(var ProductionBOMHeader: Record "Production BOM Header"; UoMCode: Code[10]; StartingDate: Date; ComponentNo: Code[20])
    var
        ProductionBOMVersion: Record "Production BOM Version";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMVersion(ProductionBOMVersion, ProductionBOMHeader."No.", LibraryUtility.GenerateGUID(), UoMCode, StartingDate);
        LibraryManufacturing.CreateProductionBOMLine(
            ProductionBOMHeader, ProductionBOMLine, ProductionBOMVersion."Version Code", Enum::"Production BOM Line Type"::Item, ComponentNo, 1);
        LibraryManufacturing.UpdateProductionBOMVersionStatus(ProductionBOMVersion, Enum::"BOM Status"::Certified);
    end;

    local procedure CreateProductionBOMWithComponentInTwoPositions(var ProductionBOMHeader: Record "Production BOM Header"; UoMCode: Code[10]; ComponentItemNo: Code[20]; QtyPer: Decimal)
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, UoMCode);
        CreateProductionBOMLineInSpecifiedPosition(
          ProductionBOMHeader, ProductionBOMLine, ComponentItemNo, QtyPer, LibraryUtility.GenerateGUID());
        CreateProductionBOMLineInSpecifiedPosition(
          ProductionBOMHeader, ProductionBOMLine, ComponentItemNo, QtyPer, LibraryUtility.GenerateGUID());
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);
    end;

    local procedure CreateProductionBOMWithOneLine(var ProductionBOMHeader: Record "Production BOM Header"; UoMCode: Code[10]; ComponentItemNo: Code[20])
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, UoMCode);
        LibraryManufacturing.CreateProductionBOMLine(
            ProductionBOMHeader, ProductionBOMLine, '', Enum::"Production BOM Line Type"::Item, ComponentItemNo, 1);
    end;

    local procedure CreatePurchOrderDropShipment(var PurchaseHeader: Record "Purchase Header"; SalesLine: Record "Sales Line")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseHeader(PurchaseHeader, SalesLine."Sell-to Customer No.");
        CreatePurchLineFromSalesLine(PurchaseLine, SalesLine, PurchaseHeader."No.");
        LibraryInventory.UpdateSalesLine(SalesLine, SalesLine.FieldNo("Unit Cost (LCY)"), PurchaseLine."Unit Cost (LCY)");
        LibraryInventory.UpdateSalesLine(SalesLine, SalesLine.FieldNo("Purchase Order No."), PurchaseLine."Document No.");
        LibraryInventory.UpdateSalesLine(SalesLine, SalesLine.FieldNo("Purch. Order Line No."), PurchaseLine."Line No.");
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; SellToCustomerNo: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        PurchaseHeader.Validate("Sell-to Customer No.", SellToCustomerNo);
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchLineFromSalesLine(var PurchaseLine: Record "Purchase Line"; SalesLine: Record "Sales Line"; DocumentNo: Code[20])
    var
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
    begin
        PurchaseLine.Init();
        PurchaseLine.Validate("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.Validate("Document No.", DocumentNo);
        PurchaseLine.Validate("Line No.", SalesLine."Line No.");
        CopyDocumentMgt.TransfldsFromSalesToPurchLine(SalesLine, PurchaseLine);
        PurchaseLine.Validate("Sales Order No.", SalesLine."Document No.");
        PurchaseLine.Validate("Sales Order Line No.", SalesLine."Line No.");
        PurchaseLine.Validate("Drop Shipment", true);
        PurchaseLine.Insert(true);
    end;

    local procedure CreateItemWithCategory(): Code[20]
    var
        Item: Record Item;
        ItemCategory: Record "Item Category";
    begin
        LibraryInventory.CreateItemCategory(ItemCategory);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Category Code", ItemCategory.Code);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateItemWithCertifiedProdBOM(ComponentItemNo: Code[20]; QtyPer: Decimal): Code[20]
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        LibraryManufacturing.CreateCertifiedProductionBOM(ProductionBOMHeader, ComponentItemNo, QtyPer);
        exit(CreateItemWithProductionBOM(ProductionBOMHeader."No."));
    end;

    local procedure CreateItemWithDimension(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        AddDimensionToItem(Item."No.", false);
        exit(Item."No.");
    end;

    local procedure CreateItemWithProductionBOM(ProductionBOMNo: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        // Random values not important.
        LibraryManufacturing.CreateItemManufacturing(
          Item, Item."Costing Method"::FIFO, LibraryRandom.RandInt(10), Item."Reordering Policy",
          Item."Flushing Method"::"Pick + Manual", '', ProductionBOMNo);
        Item.Validate("Manufacturing Policy", Item."Manufacturing Policy"::"Make-to-Order");
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure AddDimensionToItem(ItemNo: Code[20]; DifferentValue: Boolean)
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.FindDimensionValue(DimensionValue, Dimension.Code);
        if DifferentValue then
            DimensionValue.Code := LibraryDimension.FindDifferentDimensionValue(Dimension.Code, DimensionValue.Code);
        LibraryDimension.CreateDefaultDimensionItem(DefaultDimension, ItemNo, Dimension.Code, DimensionValue.Code);
    end;

    local procedure CreateAndRefreshRelProdOrder(var ProductionOrder: Record "Production Order"; SourceNo: Code[20])
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, SourceNo, 1);  // Value important.
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure UpdateProductionOrderDimension(ProductionOrderNo: Code[20]; OldDimSetID: Integer) DimensionSetID: Integer
    var
        ProductionOrder: Record "Production Order";
    begin
        // Select New Dimension Set Id.
        ProductionOrder.Get(ProductionOrder.Status::Released, ProductionOrderNo);
        DimensionSetID := SelectNewDimSetID(OldDimSetID);

        // Update Production Order Dimension with New Dimension Set Id.
        ProductionOrder.Validate("Dimension Set ID", DimensionSetID);
        ProductionOrder.Modify(true);
    end;

    local procedure SelectNewDimSetID(OldDimSetID: Integer): Integer
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
    begin
        LibraryDimension.FindDimension(Dimension);
        Dimension.Next();
        LibraryDimension.FindDimensionValue(DimensionValue, Dimension.Code);
        exit(LibraryDimension.CreateDimSet(OldDimSetID, Dimension.Code, DimensionValue.Code));
    end;

    local procedure SetQuantityPickedOnProdOrderComponent(ProdOrderStatus: Enum "Production Order Status"; ProdOrderNo: Code[20]; Quantity: Decimal)
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent.SetRange(Status, ProdOrderStatus);
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderComponent.ModifyAll("Qty. Picked", Quantity);
    end;

    local procedure FindProductionOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProductionOrder: Record "Production Order")
    begin
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
    end;

    local procedure CreateNewDimSetID(OldDimSetID: Integer): Integer
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        exit(LibraryDimension.CreateDimSet(OldDimSetID, Dimension.Code, DimensionValue.Code));
    end;

    local procedure SetDynamicLowLevelCode(NewDynamicLowLevelCode: Boolean)
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.Get();
        ManufacturingSetup.Validate("Dynamic Low-Level Code", NewDynamicLowLevelCode);
        ManufacturingSetup.Modify(true);
    end;

    local procedure UpdateProdOrderLinesDimension(ProductionOrderNo: Code[20]; OldDimSetID: Integer; DimensionSetID: Integer)
    var
        ProdOrderLine: Record "Prod. Order Line";
        DimensionManagement: Codeunit DimensionManagement;
    begin
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrderNo);
        ProdOrderLine.FindSet();
        repeat
            DimensionSetID := DimensionManagement.GetDeltaDimSetID(ProdOrderLine."Dimension Set ID", DimensionSetID, OldDimSetID);
            if ProdOrderLine."Dimension Set ID" <> DimensionSetID then begin
                ProdOrderLine.Validate("Dimension Set ID", DimensionSetID);
                DimensionManagement.UpdateGlobalDimFromDimSetID(
                  ProdOrderLine."Dimension Set ID", ProdOrderLine."Shortcut Dimension 1 Code", ProdOrderLine."Shortcut Dimension 2 Code");
                ProdOrderLine.Modify(true);
            end;
        until ProdOrderLine.Next() = 0;
    end;

    local procedure UpdateProductionOrderDimensionSetId(var ProductionOrder: Record "Production Order"; DimensionSetID: Integer)
    begin
        ProductionOrder.Validate("Dimension Set ID", DimensionSetID);
        ProductionOrder.Modify(true);
    end;

    local procedure ModifyForPartialInvoice(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        SalesLine.Validate("Qty. to Invoice", SalesLine.Quantity / 2);
        SalesLine.Modify();
    end;

    local procedure VerifyNewBatchRequisitionLine(JournalBatchName: Code[10]; DocumentNo: Code[20])
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionLine: Record "Requisition Line";
        SalesLine: Record "Sales Line";
    begin
        ReqWkshTemplate.SetRange(Type, ReqWkshTemplate.Type::"Req.");
        ReqWkshTemplate.FindFirst();
        RequisitionLine.SetRange("Worksheet Template Name", ReqWkshTemplate.Name);
        RequisitionLine.SetRange("Journal Batch Name", JournalBatchName);
        RequisitionLine.FindFirst();
        FindSalesLine(SalesLine, SalesLine."Document Type"::Order, DocumentNo);
        RequisitionLine.TestField(Type, SalesLine.Type);
        RequisitionLine.TestField("No.", SalesLine."No.");
        RequisitionLine.TestField(Quantity, SalesLine.Quantity);
    end;

    local procedure VerifySalesBlanketOrder(SalesOrderNo: Code[20]; DocumentNo: Code[20])
    var
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
    begin
        // Check the Sales Blanket Order for the Quantity Shipped field.
        FindSalesLine(SalesLine, SalesLine."Document Type"::"Blanket Order", SalesOrderNo);
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.FindFirst();
        SalesLine.TestField("Quantity Shipped", PurchaseLine."Quantity Received");
    end;

    local procedure VerifyItemCategoryCode(ItemNo: Code[20])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        ItemLedgerEntry.SetRange("Item No.", ItemNo);

        // Check for Entry Type - Purchase.
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField("Item Category Code", Item."Item Category Code");

        // Check for Entry Type - Sale.
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField("Item Category Code", Item."Item Category Code");
    end;

    local procedure VerifyLineDimension(ProductionOrderNo: Code[20])
    var
        ProductionOrder: Record "Production Order";
        DimensionSetEntry: Record "Dimension Set Entry";
        ProdOrderLine: Record "Prod. Order Line";
        DimensionCode: Code[20];
        ExpectedDimValueCode: Code[20];
    begin
        ProductionOrder.Get(ProductionOrder.Status::Released, ProductionOrderNo);
        DimensionSetEntry.SetRange("Dimension Set ID", ProductionOrder."Dimension Set ID");
        DimensionSetEntry.FindFirst();
        DimensionCode := DimensionSetEntry."Dimension Code";
        ExpectedDimValueCode := DimensionSetEntry."Dimension Value Code";
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrderNo);
        ProdOrderLine.FindSet();
        repeat
            DimensionSetEntry.SetRange("Dimension Set ID", ProdOrderLine."Dimension Set ID");
            DimensionSetEntry.SetRange("Dimension Code", DimensionCode);
            DimensionSetEntry.FindFirst();
            Assert.AreEqual(ExpectedDimValueCode, DimensionSetEntry."Dimension Value Code", UnexpectedOrderLineDimValueErr);
        until ProdOrderLine.Next() = 0;
    end;

    local procedure VerifyProductionOrderComponentDimension(ProductionOrder: Record "Production Order"; DimensionSetId: Integer; ProdOrderLineNo: Integer)
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.SetRange("Prod. Order Line No.", ProdOrderLineNo);
        ProdOrderComponent.FindFirst();
        ProdOrderComponent.TestField("Dimension Set ID", DimensionSetId);
    end;

    local procedure VerifyProductionOrderComponentPickedQuantity(ProdOrderStatus: Enum "Production Order Status"; ProdOrderNo: Code[20]; ExpectedQty: Decimal)
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent.SetRange(Status, ProdOrderStatus);
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderComponent.FindSet();
        repeat
            ProdOrderComponent.TestField("Qty. Picked", ExpectedQty);
        until ProdOrderComponent.Next() = 0;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MsgHandler(Message: Text[1024])
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerFalse(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure RefreshPickedConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(StrSubstNo(DeletePickedLinesQst, LibraryVariableStorage.DequeueText()), Question);
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;
}

