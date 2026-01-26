#if not CLEAN27
#pragma warning disable AL0801
codeunit 144081 "SCM Subcontracting"
{
    // Subcontracting:
    //  1. Verify calculate consumption after calculate planning worksheet without Procurement on Subcontracting Vendor.
    //  2. Verify calculate consumption after create Released Prod. Order with Procurement on Subcontracting Vendor.
    //  3. Verify calculate consumption after create Released Prod. Order without Procurement on Subcontracting Vendor.
    //  4. Verify error when Responsibility Center changed on Subcontraction order.
    //  5. Verify error when Currency changed on Subcontracting order.
    //  6. Verify error when Vendor No. changed on Subcontracting order.
    //  7. Verify error when change the status of Released Production Order.
    //  8. Verify Warehouse Location and Bin on Subcontracting Transfer Order.
    //  9. Verify multiple Subcontracting Order against single Released Production Order.
    // 10. Verify Location changed successfully on Subcontracting Order.
    // 11. Verify error when Subcontracting Location is blank on Vendor.
    // 12. Verify error when vendor deleted after Subcontracting Work Center.
    // 13. Verify No. and No. Series on Transfer Shipment Header use the Posted Shpt. Nos. from the Transport Reason Code after the subcontracting transfer order is posted.
    // 14. Verify Return Subcontracting Transfer Order from Subcontracting Order after post Subcontracting Transfer Order.
    // 15. Verify error at the time creating Return Subcontracting Transfer Order from Subcontracting Order while all goods has been returned.
    // 16. Verify Subcontracting Transfer Order cannot be created after posting Subcontracting Transfer Order
    // 17. Verify Return Subcontracting Transfer Order can be created after post Subcontracting Transfer Order and partial post Subcontracting Order
    //
    // Work Item ID :346240
    // --------------------------------------------------------------------------------------------------------------------------------
    //    Test Case Name                                                                                                 TFS-ID
    // --------------------------------------------------------------------------------------------------------------------------------
    // CalcConsumptionWithoutSubconProcurement                                                                          155671,155663
    // CalcConsumptionAfterRelProdOrderWithProcurement,CalcConsumptionAfterRelProdOrderWithoutProcurement               280620
    //
    // Covers Test Cases for WI - 346321
    // --------------------------------------------------------------------------------------------------------------------------------
    //    Test Case Name                                                                                                 TFS-ID
    // --------------------------------------------------------------------------------------------------------------------------------
    // ChangeResponsibilityCenterSubcontractingOrderError                                                                154619,154624
    // ChangeCurrencySubcontractingOrderError                                                                            154620
    // ChangeBuyFromVendorNoSubcontractingOrderError                                                                     154621
    // SubcontractingOrderLocationCodeChange                                                                             154622
    //
    // Covers Test Cases for WI - 347016
    // --------------------------------------------------------------------------------------------------------------------------------
    //    Test Case Name                                                                                                 TFS-ID
    // --------------------------------------------------------------------------------------------------------------------------------
    // SubcontractingOrderWithBin                                                                                        155633
    // MultipleSubconOrderWithOneReleasedProdOrder                                                                       207054
    //
    // Covers Test Cases for WI - 346319
    // --------------------------------------------------------------------------------------------------------------------------------
    //    Test Case Name                                                                                                 TFS-ID
    // --------------------------------------------------------------------------------------------------------------------------------
    // ChangeStatusProdOrderError                                                                                        280621
    // SubcontractingLocationCodeBlankError,WorkCenterWithoutVendorError                                                 280573
    //
    // Covers Test Cases for Merged Bug
    //
    // --------------------------------------------------------------------------------------------------------------------------------
    //    Test Case Name                                                                                                 TFS-ID
    // --------------------------------------------------------------------------------------------------------------------------------
    // ShipSubcontractingTransferOrderWithPostedShptNos                                                                  66339
    //
    // Covers Test Cases for WI - 347104
    // --------------------------------------------------------------------------------------------------------------------------------
    //    Test Case Name                                                                                                 TFS-ID
    // --------------------------------------------------------------------------------------------------------------------------------
    // ReturnSubconTransferOrderWithoutProcurement                                                                       155664,155672
    // ReturnSubconTransferOrderAfterAllGoodsReturnedError                                                               173852,173853
    //
    // Covers Request Hotfix for WI - 351298
    // --------------------------------------------------------------------------------------------------------------------------------
    //    Test Case Name                                                                                                 TFS-ID
    // --------------------------------------------------------------------------------------------------------------------------------
    // SubconTransferOrderAfterAllGoodsTransferedError                                                                   96657
    // ReturnSubconTransferOrderAfterPartialReceiveSubconOrder                                                           96657

    Subtype = Test;
    TestPermissions = Disabled;
    ObsoleteReason = 'Preparation for replacement by Subcontracting app';
    ObsoleteState = Pending;
    ObsoleteTag = '27.0';

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";
        ChangeStatusErr: Label 'Production Order %1 cannot be finished as the associated subcontract order %2 has not been fully delivered.';
        ProdOrderErr: Label 'You cannot update the order line because the order line is associated with production order';
        RefOrderTypeTxt: Label 'Purchase';
        ReturnTrasferOrderErr: Label 'Components to send to subcontractor do not exist.';
        UnexpectedErr: Label 'More than 1 Subcontracting Invoices are not exist.';
        VendorErr: Label 'Vendor %1 on Work Center %2 does not exist.';
        RowInNotInTheTestPageErr: Label 'The row does not exist on the TestPage.';
        NotShippedQtyForWIPItemErr: Label 'WIP Qty. is not Shipped.';
        CountryRegionErr: Label '%1 must be %2 in %3.', Comment = '%1=Field Caption ,%2=Value ,%3=Table Caption.';
        ReverseCapacityLedgerEntryForSubContractingErr: Label 'Entry cannot be reversed as it is linked to the subcontracting work center.';
        ValueMustBeEqualErr: Label '%1 must be equal to %2 in the %3.', Comment = '%1 = Field Caption , %2 = Expected Value, %3 = Table Caption';

    [Test]
    [HandlerFunctions('CalculatePlanningWkshRequestPageHandler,CarryOutActionMsgPlanRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcConsumptionWithoutSubconProcurement()
    var
        Item: Record Item;
        TransferRoute: Record "Transfer Route";
        VendorNo: Code[20];
    begin
        // Verify calculate consumption after calculate planning worksheet without Procurement on Subcontracting Vendor.

        // Setup: Create Subcontracting Location with Transfer Route, Vendor and Item with BOM & Routing.
        Initialize();
        CreateSubconLocationWithTransferRoute(TransferRoute);
        VendorNo := CreateSubcontractingVendorWithProcurement(TransferRoute."Transfer-to Code", false);  // False for Subcontractor Procurement.
        CreateItemWithProdBOMAndRouting(Item, CreateSubcontractingWorkCenter(VendorNo), TransferRoute."Transfer-from Code", '', false);  // Using blank for Routing Link Code.
        CalculatePlanningWorksheet(Item, TransferRoute."Transfer-from Code");

        // Exercise & Verify: Verify Item Ledger Entry after Calculate consumption.
        CalculateConsumptionAndVerifyItemLedgerEntry(Item."No.", TransferRoute."Transfer-from Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcConsumptionAfterRelProdOrderWithProcurement()
    begin
        // Verify calculate consumption after create Released Prod. Order with Procurement on Subcontracting Vendor.
        CalcConsumptionFromRelProdOrder(true);  // True for Subcontractor Procurement.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcConsumptionAfterRelProdOrderWithoutProcurement()
    begin
        // Verify calculate consumption after create Released Prod. Order without Procurement on Subcontracting Vendor.
        CalcConsumptionFromRelProdOrder(false);  // False for Subcontractor Procurement.
    end;

    local procedure CalcConsumptionFromRelProdOrder(Procurement: Boolean)
    var
        Item: Record Item;
        TransferRoute: Record "Transfer Route";
        VendorNo: Code[20];
    begin
        // Setup: Create Subcontracting Location with Transfer Route, Vendor and Item with BOM & Routing.
        Initialize();
        CreateSubconLocationWithTransferRoute(TransferRoute);
        VendorNo := CreateSubcontractingVendorWithProcurement(TransferRoute."Transfer-to Code", Procurement);
        CreateItemWithProdBOMAndRouting(Item, CreateSubcontractingWorkCenter(VendorNo), TransferRoute."Transfer-from Code", '', false);  // Using blank for Routing Link Code.
        CreateReleasedProductionOrder(Item."No.", TransferRoute."Transfer-from Code");

        // Exercise & Verify: Verify Item Ledger Entry after Calculate consumption.
        CalculateConsumptionAndVerifyItemLedgerEntry(Item."No.", TransferRoute."Transfer-from Code");
    end;

    // [Test]
    [HandlerFunctions('CarryOutActionMsgRequisitionRequestPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ChangeResponsibilityCenterSubcontractingOrderError()
    begin
        // Verify error when Responsibility Center changed on Subcontraction order.
        SubcontractingOrderFieldChangeError(CreateResponsibilityCenter(), '', '');  // Using blank for Vendor No. and Currency Code.
    end;

    // [Test]
    [HandlerFunctions('CarryOutActionMsgRequisitionRequestPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ChangeCurrencySubcontractingOrderError()
    begin
        // Verify error when Currency changed on Subcontraction order.
        SubcontractingOrderFieldChangeError('', CreateCurrency(), '');  // Using blank for Responsiblity center and Vendor.
    end;

    // [Test]
    [HandlerFunctions('CarryOutActionMsgRequisitionRequestPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ChangeBuyFromVendorNoSubcontractingOrderError()
    begin
        // Verify error when Vendor No. changed on Subcontraction order.
        SubcontractingOrderFieldChangeError('', '', CreateVendor());  // Using blank for Responsiblity center and Currency Code.
    end;

    local procedure SubcontractingOrderFieldChangeError(ResponsibilityCenterCode: Code[10]; CurrencyCode: Code[10]; VendorNo2: Code[20])
    var
        TransferRoute: Record "Transfer Route";
        VendorNo: Code[20];
    begin
        // Setup: Create Location and Subcontracting Order.
        Initialize();
        CreateSubconLocationWithTransferRoute(TransferRoute);
        VendorNo := CreateSubcontractingOrderWithSetup(TransferRoute."Transfer-to Code", TransferRoute."Transfer-from Code", false);

        // Exercise.
        asserterror UpdateSubcontractingOrder(VendorNo, ResponsibilityCenterCode, CurrencyCode, VendorNo2);

        // Verify: Verify actual error 'You cannot update the order line because the order line is associated with production order'.
        Assert.ExpectedError(ProdOrderErr);
    end;

    [Test]
    [HandlerFunctions('CarryOutActionMsgRequisitionRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SubcontractingOrderLocationCodeChange()
    var
        TransferRoute: Record "Transfer Route";
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
    begin
        // Verify Location changed successfully on Subcontracting Order.

        // Setup: Create Subcontracting Location and Order.
        Initialize();
        CreateSubconLocationWithTransferRoute(TransferRoute);
        VendorNo := CreateSubcontractingOrderWithSetup(TransferRoute."Transfer-to Code", TransferRoute."Transfer-from Code", false);

        // Exercise.
        UpdateLocationOnSubcontractingOrder(VendorNo, TransferRoute."Transfer-to Code");

        // Verify: Verify Location changed successfully on Subcontracting Order.
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, GetSubcontractingOrderNo(VendorNo));
        PurchaseHeader.TestField("Location Code", TransferRoute."Transfer-to Code");
    end;

    [Test]
    [HandlerFunctions('CarryOutActionMsgRequisitionRequestPageHandler,SubcontrTransferOrderModalPageHandler')]
    [Scope('OnPrem')]
    procedure SubcontractingOrderWithBin()
    var
        TransferLine: Record "Transfer Line";
        LocationCode: Code[10];
        BinCode: Code[10];
        VendorNo: Code[20];
    begin
        // Verify Warehouse Location and Bin on Subcontracting Transfer Order.

        // Setup: Create Subcontracting Order with Warehouse location and Bin.
        Initialize();
        CreateSubcontractingOrderWithWIPItemOnWMSLocation(VendorNo, LocationCode, BinCode, false, false);

        // Exercise.
        CreateSubcontractingTransferOrder(VendorNo);

        // Verify: Verify Warehouse Location and Bin on Subcontracting Transfer Order.
        TransferLine.SetRange("Transfer-from Code", LocationCode);
        TransferLine.FindFirst();
        TransferLine.TestField("Transfer-from Bin Code", BinCode);
    end;

    [Test]
    [HandlerFunctions('CarryOutActionMsgRequisitionRequestPageHandler,SubcontrTransferOrderModalPageHandler')]
    [Scope('OnPrem')]
    procedure MultipleSubconOrderWithOneReleasedProdOrder()
    var
        Item: Record Item;
        TransferRoute: Record "Transfer Route";
        PurchInvHeader: Record "Purch. Inv. Header";
        VendorNo: Code[20];
        WorkCenterNo: Code[20];
    begin
        // Verify multiple Subcontracting Order against single Released Production Order.

        // Setup: Create Subcontracting Location, Order and post.
        Initialize();
        CreateSubconLocationWithTransferRoute(TransferRoute);
        VendorNo := CreateSubcontractingVendorWithProcurement(TransferRoute."Transfer-to Code", true);  // Using True for Procurement.
        WorkCenterNo := CreateSubcontractingWorkCenter(VendorNo);
        CreateItemWithProdBOMAndRouting(Item, WorkCenterNo, TransferRoute."Transfer-from Code", '', false);  // Using blank for Routing Link Code.
        CreateReleasedProductionOrder(Item."No.", TransferRoute."Transfer-from Code");
        CreateAndPostSubcontractingOrder(Item."No.", VendorNo, VendorNo, WorkCenterNo);

        // Exercise.
        CreateAndPostSubcontractingOrder(Item."No.", VendorNo, Item."No.", WorkCenterNo);

        // Verify: Verify multiple Subcontracting Order against single Released Production Order.
        PurchInvHeader.SetRange("Buy-from Vendor No.", VendorNo);
        Assert.IsTrue(PurchInvHeader.Count > 1, UnexpectedErr);  // Using 1 to check more than one.
    end;

    [Test]
    [HandlerFunctions('CarryOutActionMsgRequisitionRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ChangeStatusProdOrderError()
    var
        TransferRoute: Record "Transfer Route";
        ProductionOrderNo: Code[20];
        VendorNo: Code[20];
    begin
        // Verify error when change the status of Released Prod. Order.

        // Setup: Create Location and Subcontracting Order.
        Initialize();
        CreateSubconLocationWithTransferRoute(TransferRoute);
        VendorNo := CreateSubcontractingOrderWithSetup(TransferRoute."Transfer-to Code", TransferRoute."Transfer-from Code", false);
        ProductionOrderNo := FindSubcontractingProdOrderNo(VendorNo);

        // Exercise.
        asserterror LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrderNo);

        // Verify: Verify actual error Production Order cannot be finished as the associated subcontract order has not been fully delivered.
        Assert.ExpectedError(StrSubstNo(ChangeStatusErr, ProductionOrderNo, GetSubcontractingOrderNo(VendorNo)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SubcontractingLocationCodeBlankError()
    var
        Item: Record Item;
        RoutingLink: Record "Routing Link";
        Vendor: Record Vendor;
        VendorNo: Code[20];
    begin
        // Verify error when Subcontracting Location is blank on Vendor.

        // Setup: Create Subcontracting Location and Order.
        Initialize();
        LibraryManufacturing.CreateRoutingLink(RoutingLink);
        VendorNo := CreateSubcontractingVendorWithProcurement('', false);  // Using blank for Location.
        CreateItemWithProdBOMAndRouting(Item, CreateSubcontractingWorkCenter(VendorNo), '', RoutingLink.Code, false);  // Using blank for Location.

        // Exercise.
        asserterror CreateReleasedProductionOrder(Item."No.", '');  // Using blank for Location.

        // Verify: Verify actual error Subcontracting Location Code must have a value in Vendor: No. It cannot be zero or empty.
        Assert.ExpectedTestFieldError(Vendor.FieldCaption("Subcontracting Location Code"), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WorkCenterWithoutVendorError()
    var
        Item: Record Item;
        RoutingLink: Record "Routing Link";
        Vendor: Record Vendor;
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        VendorNo: Code[20];
        WorkCenterNo: Code[20];
    begin
        // Verify error when vendor deleted after Subcontracting Work Center.

        // Setup: Create Subcontracting Location, Vendor, Work Center.
        Initialize();
        LibraryManufacturing.CreateRoutingLink(RoutingLink);
        VendorNo := CreateSubcontractingVendorWithProcurement('', false);  // Using blank for Location.
        WorkCenterNo := CreateSubcontractingWorkCenter(VendorNo);
        CreateItemWithProdBOMAndRouting(Item, WorkCenterNo, '', RoutingLink.Code, false);  // Using blank for Location.
        Vendor.Get(VendorNo);
        Vendor.Delete(true);

        // Exercise.
        asserterror CreateReleasedProductionOrder(Item."No.", '');  // Using blank for Location.

        // Verify: Verify actual error Vendor on Work Center does not exist.
        Assert.ExpectedError(StrSubstNo(VendorErr, VendorNo, WorkCenterNo));

        // Tear down: Delete the Work Center created as the vendor doesn't exist
        // and it will check all Subcontractor No. in function LibraryManufacturing.CalculateSubcontractOrder(WorkCenter), failed other cases.
        RoutingHeader.Get(Item."Routing No.");
        RoutingHeader.Delete();
        RoutingLine.SetRange("Routing No.", Item."Routing No.");
        RoutingLine.DeleteAll();
        WorkCenter.Get(WorkCenterNo);
        WorkCenter.Delete(true);
    end;

    [Test]
    [HandlerFunctions('CarryOutActionMsgRequisitionRequestPageHandler,SubcontrTransferOrderModalPageHandler')]
    [Scope('OnPrem')]
    procedure ShipSubcontractingTransferOrderWithPostedShptNos()
    var
        TransferRoute: Record "Transfer Route";
        SubcontractingTransferHeader: Record "Transfer Header";
        NoSeriesLine: Record "No. Series Line";
        VendorNo: Code[20];
        OptionString: Option Open,Post;
    begin
        // [FEATURE] [Subcontracting] [WIP Item]
        // [SCENARIO] No. and No. Series on Posted Transfer Shipments Header should use the Posted Shpt. Nos. from the Transport Reason Code after posted the WIP subcontracting transfer.
        Initialize();

        // [GIVEN] Create Subcontracting Location and Subcontracting Order
        CreateSubconLocationWithTransferRoute(TransferRoute);
        VendorNo := CreateSubcontractingOrderWithSetup(TransferRoute."Transfer-to Code", TransferRoute."Transfer-from Code", true);

        // Enqueue value for SubcontrTransferOrderPageHandler.
        LibraryVariableStorage.Enqueue(OptionString::Open);
        LibraryVariableStorage.Enqueue(TransferRoute."Transfer-from Code");

        // [GIVEN] Transport Reason Code "T" where Posted Shpt. Nos. = "X", whose "Last Shipment No." = "Y"
        // [GIVEN] Create Subcontracting Transfer Order, where "Transport Reason Code" = "T"
        CreateSubcontractingTransferOrder(VendorNo);
        UpdateTransportReasonCodeInSubcontractingTransferHeader(
          SubcontractingTransferHeader, TransferRoute."Transfer-from Code",
          TransferRoute."Transfer-to Code", CreateTransportReasonCodeWithPostedShptNos(NoSeriesLine));

        // [WHEN] Ship the Subcontracting Transfer Order
        LibraryInventory.PostTransferHeader(SubcontractingTransferHeader, true, false);

        // [THEN] Transfer Shipment Header's "No." = "Y"
        // [THEN] Transfer Shipment Header's "No. Series" = "X"
        VerifyNoOnTransferShipmentHeader(
          SubcontractingTransferHeader."No.", NoSeriesLine."Starting No.", NoSeriesLine."Series Code");
    end;

    [Test]
    [HandlerFunctions('CalculatePlanningWkshRequestPageHandler,CarryOutActionMsgPlanRequestPageHandler,CarryOutActionMsgRequisitionRequestPageHandler,SubcontrTransferOrderModalPageHandler')]
    [Scope('OnPrem')]
    procedure ReturnSubconTransferOrderWithoutProcurement()
    var
        TransferHeader: Record "Transfer Header";
        TransferRoute: Record "Transfer Route";
        VendorNo: Code[20];
        OptionString: Option Open,Post;
    begin
        // Verify Return Subcontracting Transfer Order can be created after posting Subcontracting Transfer Order.

        // Setup: Create a Subcontracting Order and post Subcontracting Transfer
        Initialize();
        CreateSubcontractingOrderAndPostSubcontractingTransfer(TransferRoute, VendorNo);

        // Exercise: Create Return Subcontracting Transfer Order
        LibraryVariableStorage.Enqueue(OptionString::Open); // Enqueue value for SubcontrTransferOrderModalPageHandler.
        LibraryVariableStorage.Enqueue(TransferRoute."Transfer-to Code");
        CreateReturnSubcontractingTransferOrder(VendorNo);

        // Verify: Return Subcontracting Transfer Order created successfully and Location is correct.
        TransferHeader.SetRange("Transfer-from Code", TransferRoute."Transfer-to Code");
        TransferHeader.FindFirst();
        TransferHeader.TestField("Transfer-to Code", TransferRoute."Transfer-from Code");
    end;

    [Test]
    [HandlerFunctions('CalculatePlanningWkshRequestPageHandler,CarryOutActionMsgPlanRequestPageHandler,CarryOutActionMsgRequisitionRequestPageHandler,SubcontrTransferOrderModalPageHandler')]
    [Scope('OnPrem')]
    procedure ReturnSubconTransferOrderAfterAllGoodsReturnedError()
    var
        TransferRoute: Record "Transfer Route";
        VendorNo: Code[20];
        OptionString: Option Open,Post;
    begin
        // Verify Return Subcontracting Transfer Order cannot be created after posting Subcontracting Transfer Order and all goods has been returned.

        // Setup: Create a Subcontracting Order and post Subcontracting Transfer
        Initialize();
        CreateSubcontractingOrderAndPostSubcontractingTransfer(TransferRoute, VendorNo);

        // Create Return Subcontracting Transfer Order
        LibraryVariableStorage.Enqueue(OptionString::Open); // Enqueue value for SubcontrTransferOrderModalPageHandler.
        LibraryVariableStorage.Enqueue(TransferRoute."Transfer-to Code");
        CreateReturnSubcontractingTransferOrder(VendorNo);

        // Exercise: Again, Create Return Subcontracting Transfer Order
        asserterror CreateReturnSubcontractingTransferOrder(VendorNo);

        // Verify: Error "Components to send to subcontractor do not exist." pops up.
        Assert.ExpectedError(ReturnTrasferOrderErr)
    end;

    [Test]
    [HandlerFunctions('CalculatePlanningWkshRequestPageHandler,CarryOutActionMsgPlanRequestPageHandler,CarryOutActionMsgRequisitionRequestPageHandler,SubcontrTransferOrderModalPageHandler')]
    [Scope('OnPrem')]
    procedure SubconTransferOrderAfterAllGoodsTransferedError()
    var
        TransferRoute: Record "Transfer Route";
        VendorNo: Code[20];
        OptionString: Option Open,Post;
    begin
        // Verify: Subcontracting Transfer Order cannot be created after posting Subcontracting Transfer Order

        // Setup: Create a Subcontracting Order and post Subcontracting Transfer
        Initialize();
        CreateSubcontractingOrderAndPostSubcontractingTransfer(TransferRoute, VendorNo);

        // Exercise: Create Subcontracting Transfer Order
        // Verify: Error "Components to send to subcontractor do not exist." pops up.
        LibraryVariableStorage.Enqueue(OptionString::Open); // Enqueue value for SubcontrTransferOrderModalPageHandler.
        LibraryVariableStorage.Enqueue(TransferRoute."Transfer-to Code");
        asserterror CreateSubcontractingTransferOrder(VendorNo);
        Assert.ExpectedError(ReturnTrasferOrderErr)
    end;

    [Test]
    [HandlerFunctions('CalculatePlanningWkshRequestPageHandler,CarryOutActionMsgPlanRequestPageHandler,CarryOutActionMsgRequisitionRequestPageHandler,SubcontrTransferOrderModalPageHandler')]
    [Scope('OnPrem')]
    procedure ReturnSubconTransferOrderAfterPartialReceiveSubconOrder()
    var
        TransferLine: Record "Transfer Line";
        TransferRoute: Record "Transfer Route";
        VendorNo: Code[20];
        OptionString: Option Open,Post;
        RemainQty: Decimal;
    begin
        // Verify Return Subcontracting Transfer Order can be created after post Subcontracting Transfer Order and partial post Subcontracting Order

        // Setup: Create a Subcontracting Order and post Subcontracting Transfer
        Initialize();
        CreateSubcontractingOrderAndPostSubcontractingTransfer(TransferRoute, VendorNo);

        // Post Partial Receive Subcontracting Order
        PostSubcontractingOrderWithPartialReceive(VendorNo, VendorNo, RemainQty);

        // Exercise: Create Return Subcontracting Transfer Order
        LibraryVariableStorage.Enqueue(OptionString::Open); // Enqueue value for SubcontrTransferOrderModalPageHandler.
        LibraryVariableStorage.Enqueue(TransferRoute."Transfer-to Code");
        CreateReturnSubcontractingTransferOrder(VendorNo);

        // Verify: Return Subcontracting Transfer Order created successfully and Quantity is correct.
        FindTransferLine(TransferLine, VendorNo);
        TransferLine.TestField(Quantity, Round(RemainQty, 1, '>')); // The function "Create Return from Scbcontractor" round up for field Quantity.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SubcontractingTransferIsNotPresentInTransferList()
    var
        FromLocation: Record Location;
        ToLocation: Record Location;
        InTransitLocation: Record Location;
        TransferHeader: Record "Transfer Header";
        SubcontrTransferHeader: Record "Transfer Header";
        TransferList: TestPage "Transfer Orders";
    begin
        // [FEATURE] [Subcontracting] [Transfer Order]
        // [SCENARIO 362377] Only transfer orders without subcontracting are shown in the Transfer List page

        Initialize();
        LibraryWarehouse.CreateTransferLocations(FromLocation, ToLocation, InTransitLocation);

        // [GIVEN] Transfer order without subcontracting "T1"
        // [GIVEN] Transfer order with subcontracting "T2"
        CreateTransferOrder(TransferHeader, FromLocation.Code, ToLocation.Code, InTransitLocation.Code, LibraryInventory.CreateItemNo());
        MockSubcontractingTransferOrder(
          SubcontrTransferHeader, FromLocation.Code, ToLocation.Code, InTransitLocation.Code, LibraryInventory.CreateItemNo());

        // [WHEN] "Transfer List" page is open
        TransferList.Trap();
        PAGE.Run(PAGE::"Transfer Orders");

        // [THEN] Transfer order "T1" is in the list
        TransferList.GotoRecord(TransferHeader);

        // [THEN] Transfer order "T2" is not in the list
        asserterror TransferList.GotoRecord(SubcontrTransferHeader);
        Assert.ExpectedError(RowInNotInTheTestPageErr);
    end;

    [Test]
    [HandlerFunctions('CarryOutActionMsgRequisitionRequestPageHandler,SubcontrTransferOrderModalPageHandler')]
    [Scope('OnPrem')]
    procedure SubconTransferOrderDoesNotRequireWarehouseHandlingToShip()
    var
        SubconTransferHeader: Record "Transfer Header";
        SubconTransferShipmentHeader: Record "Transfer Shipment Header";
        VendorNo: Code[20];
        LocationCode: Code[10];
        BinCode: Code[10];
    begin
        // [FEATURE] [Subcontracting] [Transfer Order] [WIP Item]
        // [SCENARIO 380156] Subcontracting Transfer Order with WIP Item does not require warehouse handling to be shipped.
        Initialize();

        // [GIVEN] Subcontracting Order for a WIP Item on Location with Bin and Shipment required.
        // [GIVEN] Transfer Order to the subcontractor's location.
        CreateSubcontractingOrderWithWIPItemOnWMSLocation(VendorNo, LocationCode, BinCode, true, true);
        CreateSubcontractingTransferOrder(VendorNo);
        FindTransferHeader(SubconTransferHeader, LocationCode);

        // [WHEN] Post the Subcontracting Transfer Order with "Ship" option.
        LibraryInventory.PostTransferHeader(SubconTransferHeader, true, false);

        // [THEN] Transfer Shipment Header is posted.
        SubconTransferShipmentHeader.Init();
        SubconTransferShipmentHeader.SetRange("Transfer Order No.", SubconTransferHeader."No.");
        Assert.RecordIsNotEmpty(SubconTransferShipmentHeader);
    end;

    [Test]
    [HandlerFunctions('CarryOutActionMsgRequisitionRequestPageHandler,SubcontrTransferOrderModalPageHandler')]
    [Scope('OnPrem')]
    procedure SubconTransferMovesExistingReservationOfProdOrderCompToInboundTransfer()
    var
        TransferLine: Record "Transfer Line";
        ProdOrderComponent: Record "Prod. Order Component";
        ReservationEntry: Record "Reservation Entry";
        ProdOrderCompReserve: Codeunit "Prod. Order Comp.-Reserve";
        TransferLineReserve: Codeunit "Transfer Line-Reserve";
        OptionString: Option Open,Post;
        VendorNo: Code[20];
        LocationFromCode: Code[10];
        LocationToCode: Code[10];
    begin
        // [FEATURE] [Subcontracting] [Transfer Order] [Prod. Order Component] [Reservation]
        // [SCENARIO 380412] Prod. Order Component which is reserved from Item Ledger Entry is become reserved from the inbound Subcontracting Transfer Order when the Transfer Order is created.
        Initialize();

        // [GIVEN] Main manufacturing location "LP", subcontractor's location "LS".
        // [GIVEN] Subcontracting Order.
        // [GIVEN] Positive inventory on a location "LP", reserved for an outstanding consumption of Prod. Order Component.
        CreateSubcontractingOrderWithReservedProdOrderComponent(ProdOrderComponent, VendorNo, LocationFromCode, LocationToCode);

        // [WHEN] Create Subcontracting Transfer Order "LP" -> "LS".
        LibraryVariableStorage.Enqueue(OptionString::Open);
        LibraryVariableStorage.Enqueue(LocationFromCode);
        CreateSubcontractingTransferOrder(VendorNo);

        // [THEN] There is one pair of reservation entries for the component Item.
        ReservationEntry.SetRange("Item No.", ProdOrderComponent."Item No.");
        Assert.RecordCount(ReservationEntry, 2);

        // [THEN] Prod. Order Component is reserved from the inbound Subcontracting Transfer Line.
        ProdOrderCompReserve.FindReservEntry(ProdOrderComponent, ReservationEntry);
        ReservationEntry.TestField(Quantity, -ProdOrderComponent."Remaining Quantity");

        FindTransferLine(TransferLine, VendorNo);
        TransferLineReserve.FindReservEntry(TransferLine, ReservationEntry, "Transfer Direction"::Inbound);
        ReservationEntry.TestField(Quantity, ProdOrderComponent."Remaining Quantity");
    end;

    [Test]
    [HandlerFunctions('CarryOutActionMsgRequisitionRequestPageHandler,SubcontrTransferOrderModalPageHandler')]
    [Scope('OnPrem')]
    procedure ProdOrderComponentIsReservedFromILECreatedOnSubconInboundTransferPost()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ProdOrderComponent: Record "Prod. Order Component";
        ReservationEntry: Record "Reservation Entry";
        ProdOrderCompReserve: Codeunit "Prod. Order Comp.-Reserve";
        ItemLedgerEntryReserve: Codeunit "Item Ledger Entry-Reserve";
        OptionString: Option Open,Post;
        VendorNo: Code[20];
        LocationFromCode: Code[10];
        LocationToCode: Code[10];
    begin
        // [FEATURE] [Subcontracting] [Transfer Order] [Prod. Order Component] [Reservation]
        // [SCENARIO 380412] When Subcontracting Transfer Order is posted, the corresponding Prod. Order Component is become reserved from the inbound transfer Item Legder Entry.
        Initialize();

        // [GIVEN] Main manufacturing location "LP", subcontractor's location "LS".
        // [GIVEN] Subcontracting Order.
        // [GIVEN] Positive inventory on a location "LP", reserved for an outstanding consumption of Prod. Order Component.
        CreateSubcontractingOrderWithReservedProdOrderComponent(ProdOrderComponent, VendorNo, LocationFromCode, LocationToCode);

        // [WHEN] Create and post Subcontracting Transfer Order "LP" -> "LS".
        LibraryVariableStorage.Enqueue(OptionString::Post);
        CreateSubcontractingTransferOrder(VendorNo);

        // [THEN] There is one pair of reservation entries for the component Item.
        ReservationEntry.SetRange("Item No.", ProdOrderComponent."Item No.");
        Assert.RecordCount(ReservationEntry, 2);

        // [THEN] Prod. Order Component is reserved from the inbound transfer Item Ledger Entry.
        ProdOrderCompReserve.FindReservEntry(ProdOrderComponent, ReservationEntry);
        ReservationEntry.TestField(Quantity, -ProdOrderComponent."Remaining Quantity");

        FindItemLedgerEntry(
          ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Transfer, ProdOrderComponent."Item No.", LocationToCode, true);
        ItemLedgerEntryReserve.FilterReservFor(ReservationEntry, ItemLedgerEntry);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField(Quantity, ProdOrderComponent."Remaining Quantity");
    end;

    [Test]
    [HandlerFunctions('CarryOutActionMsgRequisitionRequestPageHandler,SubcontrTransferOrderModalPageHandler')]
    [Scope('OnPrem')]
    procedure SubconTransferWithWIPAndOrdinaryItemWhseEntryIsPosted()
    var
        MfgLocation: Record Location;
        SubconLocation: Record Location;
        TransferRoute: Record "Transfer Route";
        Bin: Record Bin;
        CompItem: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Qty: Decimal;
        TransferQty: Decimal;
    begin
        // [FEATURE] [Subcontracting] [Transfer Order] [WIP Item] [Item] [Warehouse]
        // [SCENARIO 218610] Posting subcontracting transfer order with both WIP and ordinary item from WMS location should generate warehouse entries for the ordinary item.
        Initialize();

        // [GIVEN] Own location "L1" with mandatory bin.
        LibraryWarehouse.CreateLocationWMS(MfgLocation, true, false, false, false, false);
        LibraryWarehouse.CreateBin(Bin, MfgLocation.Code, LibraryUtility.GenerateGUID(), '', '');

        // [GIVEN] Subcontractor's location "L2".
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(SubconLocation);
        CreateTransferRoute(TransferRoute, MfgLocation.Code, SubconLocation.Code);

        // [GIVEN] "Q" pcs of item "I1" is in inventory on "L1".
        LibraryInventory.CreateItem(CompItem);
        Qty := LibraryRandom.RandIntInRange(50, 100);
        CreateAndPostItemJournalLine(CompItem."No.", MfgLocation.Code, Bin.Code, Qty);

        // [GIVEN] Production order for WIP-item "I2".
        // [GIVEN] "I1" is a component of "I2" and will be transferred to the subcontractor together with "I1" - this is set up using Routing Link.
        // [GIVEN] Subcontracting order for "I2".
        // [GIVEN] Transfer Order from "L1" to "L2" with two lines - ordinary item "I1" and WIP-item "I2".
        // [GIVEN] "Qty. to Ship" on the transfer line with "I1" = "q".
        CreateSubcontractingTransferOrderWithWIPAndOrdinaryItems(TransferHeader, CompItem, MfgLocation.Code, SubconLocation.Code);
        FindTransferLineByItemNo(TransferLine, TransferHeader."No.", CompItem."No.");
        TransferQty := TransferLine."Qty. to Ship";

        // [WHEN] Post the Subcontracting Transfer Order with "Ship" option.
        LibraryInventory.PostTransferHeader(TransferHeader, true, false);

        // [THEN] For item "I1" on location "L1": quantity in bins = inventory = "Q" - "q"
        VerifyWarehouseInventory(CompItem, MfgLocation.Code, Qty - TransferQty);
    end;

    [Test]
    [HandlerFunctions('CarryOutActionMsgRequisitionRequestPageHandler,SubcontrTransferOrderModalPageHandler')]
    [Scope('OnPrem')]
    procedure SubconTransferWithWIPAndOrdinaryItemCheckInventory()
    var
        MfgLocation: Record Location;
        SubconLocation: Record Location;
        TransferRoute: Record "Transfer Route";
        CompItem: Record Item;
        TransferHeader: Record "Transfer Header";
    begin
        // [FEATURE] [Subcontracting] [Transfer Order] [WIP Item] [Item]
        // [SCENARIO 218610] Subcontracting transfer order with both WIP and ordinary item cannot be shipped if there is not enough inventory of the ordinary item.
        Initialize();

        // [GIVEN] Own location "L1".
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(MfgLocation);

        // [GIVEN] Subcontractor's location "L2".
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(SubconLocation);
        CreateTransferRoute(TransferRoute, MfgLocation.Code, SubconLocation.Code);

        // [GIVEN] Item "I1" with no inventory on "L1".
        LibraryInventory.CreateItem(CompItem);

        // [GIVEN] Production order for WIP-item "I2".
        // [GIVEN] "I1" is a component of "I2" and will be transferred to the subcontractor together with "I1".
        // [GIVEN] Subcontracting order for "I2".
        // [GIVEN] Transfer Order from "L1" to "L2" with two lines - ordinary item "I1" and WIP-item "I2".
        CreateSubcontractingTransferOrderWithWIPAndOrdinaryItems(TransferHeader, CompItem, MfgLocation.Code, SubconLocation.Code);

        // [WHEN] Post the Subcontracting Transfer Order with "Ship" option.
        asserterror LibraryInventory.PostTransferHeader(TransferHeader, true, false);

        // [THEN] Error message is thrown.
        Assert.ExpectedError(StrSubstNo('Item %1 is not in inventory.', CompItem."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SubcontractingOrderIsNotShownInPurchaseOrderList()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOrderList: TestPage "Purchase Order List";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 201737] Subcontracting Order is not shown in Purchase Order List
        Initialize();

        // [GIVEN] Purchase Order with SubcontractingOrder = TRUE
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
          LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        PurchaseLine."Prod. Order No." := LibraryUtility.GenerateGUID();
        PurchaseLine."Prod. Order Line No." := LibraryRandom.RandInt(10);
        PurchaseLine.Modify();

        // [WHEN] Purchase Order List is opened
        PurchaseOrderList.OpenView();
        PurchaseOrderList.FILTER.SetFilter("No.", PurchaseHeader."No.");

        // [THEN] Subcontracting Order is not visible on the Purchase Order List
        PurchaseOrderList."No.".AssertEquals('');
    end;

    [Test]
    [HandlerFunctions('CarryOutActionMsgRequisitionRequestPageHandler,SubcontrTransferOrderModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostReceiptSubcontractingOrderWithTransportReasonCodeNoSeries()
    var
        TransferRoute: Record "Transfer Route";
        SubcontractingTransferHeader: Record "Transfer Header";
        NoSeriesLine: Record "No. Series Line";
        CompItem: Record Item;
        VendorNo: Code[20];
        OptionString: Option Open,Post;
    begin
        // [FEATURE] [Subcontracting] [WIP Item]
        // [SCENARIO 353097] Transfer Receipt Header uses NoSeries from TransportReasonCode."Posted Rcpt. Nos."
        Initialize();

        // [GIVEN] Create Subcontracting Location and Subcontracting Order
        CreateSubconLocationWithTransferRoute(TransferRoute);
        VendorNo := CreateSubcontractingOrderWithSetup(TransferRoute."Transfer-to Code", TransferRoute."Transfer-from Code", true);

        LibraryInventory.CreateItem(CompItem);
        CreateAndPostItemJournalLine(CompItem."No.", TransferRoute."Transfer-from Code", '', LibraryRandom.RandIntInRange(50, 100));

        // Enqueue value for SubcontrTransferOrderPageHandler.
        LibraryVariableStorage.Enqueue(OptionString::Open);
        LibraryVariableStorage.Enqueue(TransferRoute."Transfer-from Code");

        // [GIVEN] Transport Reason Code "T" where Posted Rcpt. Nos. = "X", whose "Last Receipt No." = "Y"
        // [GIVEN] Create Subcontracting Transfer Order, where "Transport Reason Code" = "T"
        CreateSubcontractingTransferOrderWithWIPAndOrdinaryItems(SubcontractingTransferHeader, CompItem, TransferRoute."Transfer-from Code", TransferRoute."Transfer-to Code");
        UpdateTransportReasonCodeInSubcontractingTransferHeader(
          SubcontractingTransferHeader, TransferRoute."Transfer-from Code",
          TransferRoute."Transfer-to Code", CreateTransportReasonCodeWithPostedRcptNos(NoSeriesLine));

        // [WHEN] Ship and receipt the Subcontracting Transfer Order
        LibraryInventory.PostTransferHeader(SubcontractingTransferHeader, true, true);

        // [THEN] Transfer Receipt Header's "No." = "Y"
        // [THEN] Transfer Receipt Header's "No. Series" = "X"
        VerifyNoOnTransferReceiptHeader(
          SubcontractingTransferHeader."No.", NoSeriesLine."Starting No.", NoSeriesLine."Series Code");
    end;

    [Test]
    [HandlerFunctions('CarryOutActionMsgRequisitionRequestPageHandler,SubcontrTransferOrderModalPageHandler')]
    procedure VerifyPostReceiveOnSubcontractingTransferOrderForWIPItem()
    var
        SubcontractingTransferHeader: Record "Transfer Header";
        CompItem: Record Item;
        TransferRoute: Record "Transfer Route";
        VendorNo: Code[20];
        OptionString: Option Open,Post;
    begin
        // [FEATURE] [Subcontracting] [WIP Item]
        // [SCENARIO 452923] Verify Post Receive on Subcontracting Transfer Order for WIP Item
        Initialize();

        // [GIVEN] Create Subcontracting Location and Subcontracting Order
        CreateSubconLocationWithTransferRoute(TransferRoute);
        VendorNo := CreateSubcontractingOrderWithSetup(TransferRoute."Transfer-to Code", TransferRoute."Transfer-from Code", true);

        // [GIVEN] Create Item
        LibraryInventory.CreateItem(CompItem);
        CreateAndPostItemJournalLine(CompItem."No.", TransferRoute."Transfer-from Code", '', LibraryRandom.RandIntInRange(50, 100));

        // Enqueue value for SubcontrTransferOrderPageHandler.
        LibraryVariableStorage.Enqueue(OptionString::Open);
        LibraryVariableStorage.Enqueue(TransferRoute."Transfer-from Code");

        // [GIVEN] Transfer Order to the subcontractor's location.
        CreateSubcontractingTransferOrderWithWIPAndOrdinaryItems(SubcontractingTransferHeader, CompItem, TransferRoute."Transfer-from Code", TransferRoute."Transfer-to Code");

        // [WHEN] Ship the Subcontracting Transfer Order
        LibraryInventory.PostTransferHeader(SubcontractingTransferHeader, true, false);

        // [THEN] Verify WIP Shipped Qty. on Subcontracting Transfer Line
        VerifyShippedQty(SubcontractingTransferHeader);

        // [THEN] Receive the Subcontracting Transfer Order
        LibraryInventory.PostTransferHeader(SubcontractingTransferHeader, false, true);
    end;

    [Test]
    [HandlerFunctions('CarryOutActionMsgRequisitionRequestPageHandler,SubcontrTransferOrderModalPageHandler')]
    procedure SubcontractingTransferOrdersCountryRegionCodes()
    var
        CountryRegion: array[2] of Record "Country/Region";
        Item: Record Item;
        Location: Record Location;
        TransferRoute: Record "Transfer Route";
        TransferReceiptHeader: Record "Transfer Receipt Header";
        Vendor: Record Vendor;
        SubcontractingOrder: TestPage "Subcontracting Order";
        OptionString: Option Open,Post;
        WorkCenterNo: Code[20];
    begin
        // [SCENARIO 540717] Subcontracting Transfer Orders Country/Region Code should be fetched from Vendor and Location.
        Initialize();

        // [GIVEN] Create two Country Regions.
        LibraryERM.CreateCountryRegion(CountryRegion[1]);
        LibraryERM.CreateCountryRegion(CountryRegion[2]);

        // [GIVEN] Create Subcontract Location with Transfer Routes.
        CreateSubconLocationWithTransferRoute(TransferRoute);

        // [GIVEN] Validate Country Region Code in Transfer from Code from Location.
        Location.Get(TransferRoute."Transfer-from Code");
        Location.Validate("Country/Region Code", CountryRegion[1].Code);
        Location.Modify(true);

        // [GIVEN] Create a Subcontractor Vendor and Validate Country Region Code.
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Subcontractor Procurement", true);
        Vendor.Validate(Subcontractor, true);
        Vendor.Validate("Subcontracting Location Code", TransferRoute."Transfer-to Code");
        Vendor.Validate("Country/Region Code", CountryRegion[2].Code);
        Vendor.Modify(true);

        // [GIVEN] Create Subcontracting Work Center.
        WorkCenterNo := CreateSubcontractingWorkCenter(Vendor."No.");

        // [GIVEN] Create an Item with Production BOM and Routing.
        CreateItemWithProdBOMAndRouting(Item, WorkCenterNo, TransferRoute."Transfer-from Code", '', false);

        // [GIVEN] Create Released Production Order.
        CreateReleasedProductionOrder(Item."No.", TransferRoute."Transfer-from Code");

        // [GIVEN] Create Subcontracting Order.
        CreateSubcontractingOrder(WorkCenterNo, Item."No.", LibraryRandom.RandInt(1));
        LibraryVariableStorage.Enqueue(OptionString::Post);

        // [WHEN] Open Subcontracting Order to create and post the Transfer Order.
        SubcontractingOrder.OpenEdit();
        SubcontractingOrder.FILTER.SetFilter("No.", GetSubcontractingOrderNo(Vendor."No."));
        SubcontractingOrder.CreateTransfOrdToSubcontractor.Invoke();
        SubcontractingOrder.Close();

        // [GIVEN] Find the Transfer Receipt Header.
        TransferReceiptHeader.SetRange("Transfer-from Code", TransferRoute."Transfer-from Code");
        TransferReceiptHeader.SetRange("Transfer-to Code", TransferRoute."Transfer-to Code");
        TransferReceiptHeader.FindFirst();

        // [THEN] Trsf.-from Country/Region Code should be same as Country/Region Code in Location.
        Assert.AreEqual(
            TransferReceiptHeader."Trsf.-from Country/Region Code",
            Location."Country/Region Code",
            StrSubstNo(
                CountryRegionErr,
                TransferReceiptHeader.FieldCaption("Trsf.-from Country/Region Code"),
                Location."Country/Region Code",
                TransferReceiptHeader.TableCaption()));

        // [THEN] Trsf.-to Country/Region Code should be same as Country/Region Code in Vendor.
        Assert.AreEqual(
            TransferReceiptHeader."Trsf.-to Country/Region Code",
            Vendor."Country/Region Code",
            StrSubstNo(
                CountryRegionErr,
                TransferReceiptHeader.FieldCaption("Trsf.-to Country/Region Code"),
                Vendor."Country/Region Code",
                TransferReceiptHeader.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,CarryOutActionMsgRequisitionRequestPageHandler,SubcontrTransferOrderModalPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyCapacityLedgerEntryMustNotBeReversedWhenSubcontractingIsTrue()
    var
        Item: Record Item;
        TransferRoute: Record "Transfer Route";
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
        CapacityLedgerEntries: TestPage "Capacity Ledger Entries";
        VendorNo: Code[20];
        WorkCenterNo: Code[20];
    begin
        // [SCENARIO 562491] Verify Capacity Ledger Entry must not be reversed When "Subcontracting" is true on Capacity Ledger Entry.
        Initialize();

        // [GIVEN] Create Subcontracting Location with Transfer Route.
        CreateSubconLocationWithTransferRoute(TransferRoute);

        // [GIVEN] Create Subcontracting Vendor.
        VendorNo := CreateSubcontractingVendorWithProcurement(TransferRoute."Transfer-to Code", true);

        // [GIVEN] Create Subcontracting Work Center.
        WorkCenterNo := CreateSubcontractingWorkCenter(VendorNo);

        // [GIVEN] Create Item With Production BOM and Routing.
        CreateItemWithProdBOMAndRouting(Item, WorkCenterNo, TransferRoute."Transfer-from Code", '', false);

        // [GIVEN] Create and Refresh Released Production Order.
        CreateReleasedProductionOrder(Item."No.", TransferRoute."Transfer-from Code");

        // [GIVEN] Create And Post Subcontracting Order.
        CreateAndPostSubcontractingOrder(Item."No.", VendorNo, VendorNo, WorkCenterNo);

        // [GIVEN] Find Capacity Ledger Entry.
        FindCapacityLedgerEntry(CapacityLedgerEntry, WorkCenterNo);

        // [WHEN] Reverse Capacity Ledger Entry.
        CapacityLedgerEntries.OpenEdit();
        CapacityLedgerEntries.GoToRecord(CapacityLedgerEntry);
        asserterror CapacityLedgerEntries.Reverse.Invoke();

        // [THEN] Capacity Ledger Entry must not be reversed When "Subcontracting" is true on Capacity Ledger Entry.
        Assert.ExpectedError(ReverseCapacityLedgerEntryForSubContractingErr)
    end;

    [Test]
    [HandlerFunctions('PostProductionJournalHandler,MessageHandler,ConfirmHandler')]
    procedure VerifyReverseItemLedgerEntryShouldBeCreatedForConsumptionWhenReverseIsExecuted()
    var
        OutputItem: Record Item;
        CompItem: Record Item;
        ManufacturingSetup: Record "Manufacturing Setup";
        TransferRoute: Record "Transfer Route";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemLedgerEntries: TestPage "Item Ledger Entries";
        VendorNo: Code[20];
        WorkCenterNo: Code[20];
    begin
        // [SCENARIO 567053] Verify Reverse Entry should be created of Item Ledger Entry for Entry Type "Consumption" when Reverse action is executed.
        // if there is production order with Routing with subcontracting.
        Initialize();

        // [GIVEN] Get "Inventory Setup".
        ManufacturingSetup.Get();

        // [GIVEN] Create Subcontracting Location with Transfer Route.
        CreateSubconLocationWithTransferRoute(TransferRoute);

        // [GIVEN] Create Subcontracting Vendor.
        VendorNo := CreateSubcontractingVendorWithProcurement(TransferRoute."Transfer-to Code", true);

        // [GIVEN] Create Subcontracting Work Center.
        WorkCenterNo := CreateSubcontractingWorkCenter(VendorNo);

        // [GIVEN] Create Item With Production BOM and Routing.
        CreateItemWithProdBOMAndRouting(OutputItem, WorkCenterNo, TransferRoute."Transfer-from Code", '', false);

        // [GIVEN] Create Item Setup.
        CreateItemsSetup(OutputItem, CompItem, LibraryRandom.RandIntInRange(1, 10));

        // [GIVEN] Create and Post Item Journal Line for Component item.
        CreateAndPostItemJournalLine(CompItem."No.", LibraryRandom.RandIntInRange(100, 200), '', ManufacturingSetup."Components at Location");

        // [GIVEN] Create and refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, OutputItem."No.", LibraryRandom.RandIntInRange(1, 10), '', '');

        // [GIVEN] Find Released Production Order Line.
        FindProdOrderLine(ProdOrderLine, ProdOrderLine.Status::Released, ProductionOrder."No.");

        // [GIVEN] Open and Post Production Journal.
        LibraryManufacturing.OpenProductionJournal(ProductionOrder, ProdOrderLine."Line No.");

        // [GIVEN] OpenEdit Item Ledger Entries.
        ItemLedgerEntries.OpenEdit();
        ItemLedgerEntries.Filter.SetFilter("Document No.", ProductionOrder."No.");
        ItemLedgerEntries.Filter.SetFilter("Entry Type", Format(ItemLedgerEntry."Entry Type"::Consumption));

        // [WHEN] Invoke "Reverse" action.
        ItemLedgerEntries.Reverse.Invoke();

        // [THEN] Verify Reverse Entry should be created of Item Ledger Entry for Entry Type "Consumption".
        ItemLedgerEntry.Get(ItemLedgerEntries."Entry No.".AsInteger());
        FindLastItemLedgerEntry(ItemLedgerEntry, "Inventory Order Type"::Production, ProductionOrder."No.", ItemLedgerEntry."Order Line No.", "Item Ledger Entry Type"::Consumption);
        Assert.AreEqual(
            -ItemLedgerEntries.Quantity.AsInteger(),
            ItemLedgerEntry.Quantity,
            StrSubstNo(ValueMustBeEqualErr, ItemLedgerEntry.FieldCaption(Quantity), -ItemLedgerEntries.Quantity.AsInteger(), ItemLedgerEntry.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure CalculateSubcontractsWithBlockedAndNonBlockedItems()
    var
        ChildItem: Record Item;
        Item: array[5] of Record Item;
        ProductionBOMHeader: array[5] of Record "Production BOM Header";
        RequisitionLine: Record "Requisition Line";
        ReqWkshName: Record "Requisition Wksh. Name";
        RoutingHeader: array[5] of Record "Routing Header";
        Vendor: Record Vendor;
        CalculateSubcontracts: Report "Calculate Subcontracts";
        WorkCenterNo: Code[20];
        i: Integer;
    begin
        // [SCENARIO 601443] Ensure that the process does not stop when a blocked item occurs, and the remaining non-blocked items are process in the Subcontracting Worksheet.
        Initialize();

        // [GIVEN] Create subcontractor vendor
        CreateSubcontractorVendor(Vendor);

        // [GIVEN] Create Child Item.
        LibraryInventory.CreateItem(ChildItem);

        // [GIVEN] Create work center with subcontractor.
        WorkCenterNo := CreateSubcontractingWorkCenter(Vendor."No.");

        for i := 1 to LibraryRandom.RandIntInRange(3, 5) do begin
            // [GIVEN] Create a new Production BOM.
            CreateProductionBOM(ProductionBOMHeader[i], ChildItem);

            // [GIVEN] Create Routing and Certified.
            CreateRoutingWithWorkCenter(RoutingHeader[i], WorkCenterNo);

            // [GIVEN] Create Manufacturing Item.
            CreateItemManufacturing(Item[i], ProductionBOMHeader[i]."No.", RoutingHeader[i]."No.");

            // [GIVEN] Create Released Production Order
            CreateReleasedProductionOrder(Item[i]."No.", '');
        end;

        // [GIVEN] Block Item 1 and Item 3 but keep Item 2 unblocked.
        BlockedItem(Item[1]);
        BlockedItem(Item[3]);

        // [GIVEN] Setup requisition worksheet
        GetReqWkshTemplateAndBatch(ReqWkshName);
        RequisitionLine.Init();
        RequisitionLine.Validate("Worksheet Template Name", ReqWkshName."Worksheet Template Name");
        RequisitionLine.Validate("Journal Batch Name", ReqWkshName.Name);

        // [WHEN] Run Calculate Subcontracts report.
        CalculateSubcontracts.SetWkShLine(RequisitionLine);
        CalculateSubcontracts.UseRequestPage(false);
        CalculateSubcontracts.Run();

        // [THEN] Verify: Check that requisition line was created for non-blocked item
        RequisitionLine.SetRange("Worksheet Template Name", ReqWkshName."Worksheet Template Name");
        RequisitionLine.SetRange("Journal Batch Name", ReqWkshName.Name);
        RequisitionLine.SetRange("No.", Item[2]."No.");
        Assert.IsFalse(RequisitionLine.IsEmpty(), 'Requisition line should be created for non-blocked item');

        // [THEN] Verify: Check that no requisition line was created for blocked item
        RequisitionLine.SetRange("No.");
        RequisitionLine.SetFilter("No.", '%1|%2', Item[1]."No.", Item[3]."No.");
        Assert.IsTrue(RequisitionLine.IsEmpty(), 'No requisition line should be created for blocked item');
    end;

    local procedure Initialize()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryVariableStorage.Clear();
        PurchaseHeader.DontNotifyCurrentUserAgain(PurchaseHeader.GetModifyVendorAddressNotificationId());
        PurchaseHeader.DontNotifyCurrentUserAgain(PurchaseHeader.GetModifyPayToVendorAddressNotificationId());
        CreateVATPostingSetup();
    end;

    local procedure AddTempRoutingLine(var TempRoutingLine: Record "Routing Line" temporary; OperationNo: Integer; WorkCenterNo: Code[20]; RoutingLinkCode: Code[10]; IsWIPItem: Boolean)
    begin
        TempRoutingLine.Init();
        TempRoutingLine."Operation No." := Format(OperationNo);
        TempRoutingLine."Work Center No." := WorkCenterNo;
        TempRoutingLine."Routing Link Code" := RoutingLinkCode;
        TempRoutingLine."WIP Item" := IsWIPItem;
        TempRoutingLine.Insert();
    end;

    local procedure CalculateConsumptionAndVerifyItemLedgerEntry(ItemNo: Code[20]; LocationCode: Code[10])
    begin
        // Exercise.
        CalculateAndPostConsumptionJournal(ItemNo, LocationCode);

        // Verify.
        VerifyItemLedgerEntry(ItemNo, LocationCode);
    end;

    local procedure CalculateAndPostConsumptionJournal(ItemNo: Code[20]; LocationCode: Code[10])
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
        ProductionOrder: Record "Production Order";
    begin
        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        LibraryManufacturing.CalculateConsumption(GetProductionOrderNo(
            ProductionOrder.Status::Released, ItemNo), ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        UpdateItemJournalLine(ItemJournalBatch, LocationCode);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CalculatePlanningWorksheet(Item: Record Item; LocationCode: Code[10])
    var
        ProductionOrder: Record "Production Order";
        ItemFilter: Text[30];
        ItemVendorNo: Code[20];
    begin
        // Create Sales Order for FG item, update Reordering Policy and Replenishment on child items and Calculate Regenerative plan on Planning Worksheet.
        CreateSalesOrder(Item."No.", LocationCode);
        ItemFilter := UpdateChildItem(Item."Production BOM No.");
        LibraryVariableStorage.Enqueue(Item."No." + ItemFilter);  // Call CalculatePlanningWkshRequestPageHandler.
        CalculateRegenerativePlanFromPlanningWorksheet();

        // Update Planning Worksheet and Carryout Action message for creating Production order for FG item.
        UpdatePlanningRequisitionLine(Item."No." + ItemFilter);
        ItemVendorNo := UpdateItemVendorNoOnPlanningWorksheet(CopyStr(ItemFilter, 2, 10));
        CarryOutActionMessageFromPlanningWorksheet();

        // Purchase Order for child items and change status of Firm Planned to Released Production Order.
        ReceivePurchaseOrderForChildItem(ItemVendorNo);
        LibraryManufacturing.ChangeStatusFirmPlanToReleased(GetProductionOrderNo(ProductionOrder.Status::"Firm Planned", Item."No."));
    end;

    local procedure CalculateRegenerativePlanFromPlanningWorksheet()
    var
        PlanningWorksheet: TestPage "Planning Worksheet";
    begin
        Commit();  // Commit required for run batch report.
        PlanningWorksheet.OpenEdit();
        PlanningWorksheet.CalculateRegenerativePlan.Invoke();  // Call CalculatePlanningWkshRequestPageHandler.
        PlanningWorksheet.Close();
    end;

    local procedure CarryOutActionMessageFromPlanningWorksheet()
    var
        PlanningWorksheet: TestPage "Planning Worksheet";
    begin
        Commit();  // Commit required for run batch report.
        PlanningWorksheet.OpenEdit();
        PlanningWorksheet.CarryOutActionMessage.Invoke();  // Call CarryOutActionMsgPlanRequestPageHandler.
        PlanningWorksheet.Close();
    end;

    local procedure CarryOutActionMessageFromSubcontractingWorksheet()
    var
        SubcontractingWorksheet: TestPage "Subcontracting Worksheet";
    begin
        Commit();  // Commit required for run batch report.
        SubcontractingWorksheet.OpenEdit();
        SubcontractingWorksheet.CarryOutActionMessage.Invoke();  // Call CarryOutActionMsgRequsitionRequestPageHandler.
        SubcontractingWorksheet.Close();
    end;

    local procedure CreateAndPostItemJournalLine(ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, LocationCode, BinCode, Quantity);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateAndPostSubcontractingOrder(ItemNo: Code[20]; VendorNo: Code[20]; VendorInvoiceNo: Code[20]; WorkCenterNo: Code[20])
    var
        OptionString: Option Open,Post;
    begin
        CreateSubcontractingOrder(WorkCenterNo, ItemNo, 2);  // Using 2 for partial value.
        LibraryVariableStorage.Enqueue(OptionString::Post);  // Enqueue value for SubcontrTransferOrderPageHandler.
        CreateSubcontractingTransferOrder(VendorNo);
        PostSubcontractingOrder(VendorNo, VendorInvoiceNo);
    end;

    local procedure CreateBinContent(var Bin: Record Bin; Item: Record Item; LocationCode: Code[20])
    var
        BinContent: Record "Bin Content";
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationCode, false);  // Using False for Default.
        LibraryWarehouse.CreateBin(
          Bin, WarehouseEmployee."Location Code", LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), DATABASE::Bin), '', '');  // Using blank for Zone and Bin Type code.
        LibraryWarehouse.CreateBinContent(
          BinContent, WarehouseEmployee."Location Code", '', Bin.Code, Item."No.", '', Item."Base Unit of Measure");  // Using blank for Zone and Variant code.
        BinContent.Validate(Fixed, true);
        BinContent.Validate(Default, true);
        BinContent.Modify(true);
    end;

    local procedure CreateBinContentForChildItem(ProductionBOMNo: Code[20]; LocationCode: Code[20]): Code[10]
    var
        Bin: Record Bin;
        Item: Record Item;
        ProductionBOMLine: Record "Production BOM Line";
    begin
        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMNo);
        ProductionBOMLine.SetRange(Type, ProductionBOMLine.Type::Item);
        ProductionBOMLine.FindFirst();
        Item.Get(ProductionBOMLine."No.");
        CreateBinContent(Bin, Item, LocationCode);
        exit(Bin.Code);
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateReleasedProductionOrder(ItemNo: Code[20]; LocationCode: Code[20])
    var
        ProductionOrder: Record "Production Order";
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo,
          LibraryRandom.RandInt(10));  // Using Random for Quantity.
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, true, true, true, true, false);  // Using booleans for Forward,CalcLines,CalcRoutings,CalcComponents and CreateInbRqst.
    end;

    local procedure CreateReturnSubcontractingTransferOrder(VendorNo: Code[20])
    var
        SubcontractingOrder: TestPage "Subcontracting Order";
    begin
        // Create Transfer order from Subcontracting Order.
        SubcontractingOrder.OpenEdit();
        SubcontractingOrder.FILTER.SetFilter("No.", GetSubcontractingOrderNo(VendorNo));
        SubcontractingOrder.CreateReturnFromSubcontractor.Invoke();
        SubcontractingOrder.Close();
    end;

    local procedure CreateItemManufacturing(var Item: Record Item; ProdBOMNo: Code[20]; RoutingNo: Code[20])
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Production BOM No.", ProdBOMNo);
        Item.Validate("Routing No.", RoutingNo);
        Item.Modify(true);
    end;

    local procedure CreateItemAndUpdateInventory(LocationCode: Code[10]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        CreateAndPostItemJournalLine(Item."No.", LocationCode, '', LibraryRandom.RandIntInRange(100, 200));
        exit(Item."No.");
    end;

    local procedure CreateItemWithProdBOMAndRouting(var Item: Record Item; WorkCenterNo: Code[20]; LocationCode: Code[10]; RoutingLinkCode: Code[10]; WipItem: Boolean): Code[20]
    begin
        LibraryInventory.CreateItem(Item);
        CreateProductionBOMWithRouting(Item, WorkCenterNo, LocationCode, RoutingLinkCode, WipItem);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::Order);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateCertifiedProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; CompItem: Record Item; RoutingLinkCode: Code[10])
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, CompItem."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, CompItem."No.", 1);
        ProductionBOMLine.Validate("Routing Link Code", RoutingLinkCode);
        ProductionBOMLine.Modify(true);
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);
    end;

    local procedure CreateCertifiedRouting(var RoutingHeader: Record "Routing Header"; var TempRoutingLine: Record "Routing Line" temporary)
    var
        RoutingLine: Record "Routing Line";
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);

        TempRoutingLine.FindSet();
        repeat
            LibraryManufacturing.CreateRoutingLine(
              RoutingHeader, RoutingLine, '', TempRoutingLine."Operation No.",
              RoutingLine.Type::"Work Center", TempRoutingLine."Work Center No.");
            RoutingLine.Validate("WIP Item", TempRoutingLine."WIP Item");
            RoutingLine.Validate("Routing Link Code", TempRoutingLine."Routing Link Code");
            RoutingLine.Modify(true);
        until TempRoutingLine.Next() = 0;

        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
    end;

    local procedure CreateProductionBOMWithRouting(var Item: Record Item; WorkCenterNo: Code[20]; LocationCode: Code[10]; RoutingLinkCode: Code[10]; WipItem: Boolean)
    var
        ItemVendor: Record "Item Vendor";
        ItemVendor2: Record "Item Vendor";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionBOMLine2: Record "Production BOM Line";
        RoutingHeader: Record "Routing Header";
        TempRoutingLine: Record "Routing Line" temporary;
        Vendor: Record Vendor;
    begin
        AddTempRoutingLine(TempRoutingLine, 1, CreateWorkCenter(), '', false);
        AddTempRoutingLine(TempRoutingLine, 2, WorkCenterNo, RoutingLinkCode, WipItem);
        CreateCertifiedRouting(RoutingHeader, TempRoutingLine);
        LibraryPurchase.CreateVendor(Vendor);

        // Create Production BOM and Item Vendor for each child item.
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, CreateItemAndUpdateInventory(LocationCode), 1);  // Using 1 for Per Item.
        LibraryInventory.CreateItemVendor(ItemVendor, Vendor."No.", ProductionBOMLine."No.");
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine2, '', ProductionBOMLine.Type::Item, CreateItemAndUpdateInventory(LocationCode), 1);  // Using 1 for Per Item.
        LibraryInventory.CreateItemVendor(ItemVendor2, Vendor."No.", ProductionBOMLine2."No.");

        // Certified Production BOM.
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);

        Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item.Modify(true);
    end;

    local procedure CreateResponsibilityCenter(): Code[10]
    var
        ResponsibilityCenter: Record "Responsibility Center";
    begin
        LibraryService.CreateResponsibilityCenter(ResponsibilityCenter);
        exit(ResponsibilityCenter.Code);
    end;

    local procedure CreateSalesOrder(No: Code[20]; LocationCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        SalesHeader.Validate("Location Code", LocationCode);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, No, LibraryRandom.RandIntInRange(50, 100));  // Using Random for Quantity in range.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(10, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateSubcontractingOrder(WorkCenterNo: Code[20]; SourceNo: Code[20]; PartialValue: Integer)
    var
        ProductionOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        SubcontractingWorksheet: TestPage "Subcontracting Worksheet";
        Quantity: Decimal;
    begin
        // Calculate Subcontracting Order from Subcontracting Worksheet.
        WorkCenter.Get(WorkCenterNo);
        LibraryManufacturing.CalculateSubcontractOrder(WorkCenter);
        SubcontractingWorksheet.OpenEdit();
        SubcontractingWorksheet.FILTER.SetFilter("Prod. Order No.", GetProductionOrderNo(ProductionOrder.Status::Released, SourceNo));
        SubcontractingWorksheet.First();
        SubcontractingWorksheet."Due Date".SetValue(CalcDate('<-1D>', WorkDate()));
        Evaluate(Quantity, SubcontractingWorksheet.Quantity.Value);
        SubcontractingWorksheet.Quantity.SetValue(Quantity / PartialValue);
        SubcontractingWorksheet.Close();

        // Carryout Action message from Subcontracting Worksheet to create Subcontracting Order.
        CarryOutActionMessageFromSubcontractingWorksheet();
    end;

    local procedure CreateSubcontractingOrderWithSetup(LocationCode: Code[10]; LocationCode2: Code[10]; WipItem: Boolean) VendorNo: Code[20]
    var
        Item: Record Item;
        WorkCenterNo: Code[20];
    begin
        VendorNo := CreateSubcontractingVendorWithProcurement(LocationCode, false);  // Subcontracting Location.
        WorkCenterNo := CreateSubcontractingWorkCenter(VendorNo);
        CreateItemWithProdBOMAndRouting(Item, WorkCenterNo, LocationCode2, '', WipItem);  // Mfg. Location.
        CreateReleasedProductionOrder(Item."No.", LocationCode2);
        CreateSubcontractingOrder(WorkCenterNo, Item."No.", 1);  // Using 1 for full Quantity.
    end;

    local procedure CreateSubcontractingOrderWithBin(Item: Record Item; TransferFromCode: Code[20]; TransferToCode: Code[20]; WorkCenterNo: Code[20]) BinCode: Code[10]
    var
        TransferRoute: Record "Transfer Route";
    begin
        CreateTransferRoute(TransferRoute, TransferFromCode, TransferToCode);
        BinCode := CreateBinContentForChildItem(Item."Production BOM No.", TransferFromCode);
        CreateReleasedProductionOrder(Item."No.", TransferFromCode);
        CreateSubcontractingOrder(WorkCenterNo, Item."No.", 1);  // Using 1 for full Quantity.
    end;

    local procedure CreateSubcontractingOrderWithWIPItemOnWMSLocation(var VendorNo: Code[20]; var LocationCode: Code[10]; var BinCode: Code[10]; RequireShipment: Boolean; WIPItem: Boolean)
    var
        TransferRoute: Record "Transfer Route";
        Location: Record Location;
        Item: Record Item;
        WorkCenterNo: Code[20];
        OptionString: Option Open,Post;
    begin
        CreateSubconLocationWithTransferRoute(TransferRoute);
        VendorNo := CreateSubcontractingVendorWithProcurement(TransferRoute."Transfer-to Code", false);
        WorkCenterNo := CreateSubcontractingWorkCenter(VendorNo);
        LocationCode := CreateWarehouseLocation();
        CreateItemWithProdBOMAndRouting(Item, WorkCenterNo, TransferRoute."Transfer-from Code", '', WIPItem);
        BinCode :=
          CreateSubcontractingOrderWithBin(Item, LocationCode, TransferRoute."Transfer-to Code", WorkCenterNo);

        Location.Get(LocationCode);
        Location.Validate("Require Shipment", RequireShipment);
        Location.Modify(true);

        LibraryVariableStorage.Enqueue(OptionString::Open);
        LibraryVariableStorage.Enqueue(Location.Code);
    end;

    local procedure CreateSubcontractingOrderAndPostSubcontractingTransfer(var TransferRoute: Record "Transfer Route"; var VendorNo: Code[20])
    var
        Item: Record Item;
        WorkCenterNo: Code[20];
        OptionString: Option Open,Post;
    begin
        // Setup: Create Subcontracting Location with Transfer Route, Vendor and Item with BOM & Routing, Work Center.
        CreateSubconLocationWithTransferRoute(TransferRoute);
        VendorNo := CreateSubcontractingVendorWithProcurement(TransferRoute."Transfer-to Code", false); // False for Subcontractor Procurement.
        WorkCenterNo := CreateSubcontractingWorkCenter(VendorNo);
        CreateItemWithProdBOMAndRouting(Item, WorkCenterNo, TransferRoute."Transfer-from Code", '', false); // Using blank for Routing Link Code.
        CalculatePlanningWorksheet(Item, TransferRoute."Transfer-from Code");
        CreateSubcontractingOrder(WorkCenterNo, Item."No.", 1); // Using 1 for full Quantity.

        // Create and post Subcontracting Transfer Order.
        LibraryVariableStorage.Enqueue(OptionString::Post);
        CreateSubcontractingTransferOrder(VendorNo);
    end;

    local procedure CreateSubcontractingOrderWithReservedProdOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; var VendorNo: Code[20]; var LocationFromCode: Code[10]; var LocationToCode: Code[10])
    var
        Item: Record Item;
        TransferRoute: Record "Transfer Route";
    begin
        CreateSubconLocationWithTransferRoute(TransferRoute);
        LocationFromCode := TransferRoute."Transfer-from Code";
        LocationToCode := TransferRoute."Transfer-to Code";

        VendorNo := CreateSubcontractingOrderWithSetup(LocationToCode, LocationFromCode, false);

        ProdOrderComponent.SetRange("Prod. Order No.", FindSubcontractingProdOrderNo(VendorNo));
        ProdOrderComponent.FindFirst();
        Item.Get(ProdOrderComponent."Item No.");
        Item.Validate(Reserve, Item.Reserve::Always);
        Item.Modify(true);

        CreateAndPostItemJournalLine(ProdOrderComponent."Item No.", LocationFromCode, '', ProdOrderComponent."Remaining Quantity");

        ProdOrderComponent.AutoReserve();
    end;

    local procedure CreateSubcontractingVendorWithProcurement(SubcontractingLocationCode: Code[10]; SubcontractorProcurement: Boolean): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Subcontractor Procurement", SubcontractorProcurement);
        Vendor.Validate(Subcontractor, true);
        Vendor.Validate("Subcontracting Location Code", SubcontractingLocationCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateSubcontractingWorkCenter(SubcontractorNo: Code[20]): Code[20]
    var
        WorkCenter: Record "Work Center";
    begin
        WorkCenter.Get(CreateWorkCenter());
        WorkCenter.Validate("Direct Unit Cost", LibraryRandom.RandDec(20, 2));
        WorkCenter.Validate("Unit Cost", WorkCenter."Direct Unit Cost");
        WorkCenter.Validate("Unit Cost Calculation", WorkCenter."Unit Cost Calculation"::Units);
        WorkCenter.Validate("Subcontractor No.", SubcontractorNo);
        WorkCenter.Modify(true);
        exit(WorkCenter."No.");
    end;

    local procedure CreateSubconLocationWithTransferRoute(var TransferRoute: Record "Transfer Route")
    var
        Location: Record Location;
        Location2: Record Location;
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);  // Subcontracting Location.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location2);  // Mfg. Location.
        CreateTransferRoute(TransferRoute, Location2.Code, Location.Code);
        CreateTransferRoute(TransferRoute, Location.Code, Location2.Code); // It is necessary when creating Return Subcontracting Transfer Order
    end;

    local procedure CreateSubcontractingTransferOrder(VendorNo: Code[20])
    var
        SubcontractingOrder: TestPage "Subcontracting Order";
    begin
        // Create Transfer order from Subcontracting Order.
        SubcontractingOrder.OpenEdit();
        SubcontractingOrder.FILTER.SetFilter("No.", GetSubcontractingOrderNo(VendorNo));
        SubcontractingOrder.CreateTransfOrdToSubcontractor.Invoke();  // Transfer order post in SubcontrTransferOrderPageHandler.
        SubcontractingOrder.Close();
    end;

    local procedure CreateSubcontractingTransferOrderWithWIPAndOrdinaryItems(var TransferHeader: Record "Transfer Header"; CompItem: Record Item; MfgLocationCode: Code[10]; SubconLocationCode: Code[10])
    var
        MfgItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        RoutingHeader: Record "Routing Header";
        TempRoutingLine: Record "Routing Line" temporary;
        RoutingLink: Record "Routing Link";
        VendorNo: Code[20];
        WorkCenterNo: Code[20];
        OptionString: Option Open,Post;
    begin
        VendorNo := CreateSubcontractingVendorWithProcurement(SubconLocationCode, false);
        WorkCenterNo := CreateSubcontractingWorkCenter(VendorNo);

        LibraryManufacturing.CreateRoutingLink(RoutingLink);
        CreateCertifiedProductionBOM(ProductionBOMHeader, CompItem, RoutingLink.Code);

        AddTempRoutingLine(TempRoutingLine, 1, CreateWorkCenter(), '', false);
        AddTempRoutingLine(TempRoutingLine, 2, WorkCenterNo, '', true);
        AddTempRoutingLine(TempRoutingLine, 3, WorkCenterNo, RoutingLink.Code, false);
        CreateCertifiedRouting(RoutingHeader, TempRoutingLine);

        CreateItemManufacturing(MfgItem, ProductionBOMHeader."No.", RoutingHeader."No.");

        CreateReleasedProductionOrder(MfgItem."No.", MfgLocationCode);
        CreateSubcontractingOrder(WorkCenterNo, MfgItem."No.", 1);

        LibraryVariableStorage.Enqueue(OptionString::Open);
        LibraryVariableStorage.Enqueue(MfgLocationCode);
        CreateSubcontractingTransferOrder(VendorNo);

        FindTransferHeader(TransferHeader, MfgLocationCode);
    end;

    local procedure CreateTransferOrder(var TransferHeader: Record "Transfer Header"; FromLocationCode: Code[10]; ToLocationCode: Code[10]; InTransitCode: Code[10]; ItemNo: Code[20])
    var
        TransferLine: Record "Transfer Line";
    begin
        LibraryInventory.CreateTransferHeader(TransferHeader, FromLocationCode, ToLocationCode, InTransitCode);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, ItemNo, LibraryRandom.RandDec(100, 2));
    end;

    local procedure CreateTransferRoute(var TransferRoute: Record "Transfer Route"; TransferFromCode: Code[20]; TransferToCode: Code[20])
    var
        Location: Record Location;
    begin
        LibraryWarehouse.CreateInTransitLocation(Location);
        LibraryInventory.CreateTransferRoute(TransferRoute, TransferFromCode, TransferToCode);
        TransferRoute.Validate("In-Transit Code", Location.Code);
        TransferRoute.Modify(true);
    end;

    local procedure CreateVATPostingSetup()
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATBusinessPostingGroup.FindSet();
        repeat
            if not VATPostingSetup.Get(VATBusinessPostingGroup.Code, '') then
                LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, '');
        until VATBusinessPostingGroup.Next() = 0;
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        exit(Vendor."No.");
    end;

    local procedure CreateWorkCenter(): Code[20]
    var
        WorkCenter: Record "Work Center";
    begin
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        exit(WorkCenter."No.");
    end;

    local procedure CreateWarehouseLocation(): Code[10]
    var
        Location: Record Location;
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Bin Mandatory", true);
        Location.Validate("Default Bin Selection", Location."Default Bin Selection"::"Fixed Bin");
        Location.Modify(true);
        exit(Location.Code);
    end;

    local procedure CreateTransportReasonCodeWithPostedShptNos(var NoSeriesLine: Record "No. Series Line"): Code[20]
    var
        TransportReasonCode: Record "Transport Reason Code";
        NoSeries: Record "No. Series";
    begin
        LibraryUtility.CreateNoSeries(NoSeries, true, false, false);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, '', '');
        TransportReasonCode.Init();
        TransportReasonCode.Validate(Code, LibraryUtility.GenerateRandomCode(TransportReasonCode.FieldNo(Code), DATABASE::"Transport Reason Code"));
        TransportReasonCode.Validate("Posted Shpt. Nos.", NoSeries.Code);
        TransportReasonCode.Insert(true);
        exit(TransportReasonCode.Code)
    end;

    local procedure CreateTransportReasonCodeWithPostedRcptNos(var NoSeriesLine: Record "No. Series Line"): Code[20]
    var
        TransportReasonCode: Record "Transport Reason Code";
        NoSeries: Record "No. Series";
    begin
        LibraryUtility.CreateNoSeries(NoSeries, true, false, false);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, '', '');
        TransportReasonCode.Init();
        TransportReasonCode.Validate(Code, LibraryUtility.GenerateRandomCode(TransportReasonCode.FieldNo(Code), DATABASE::"Transport Reason Code"));
        TransportReasonCode.Validate("Posted Rcpt. Nos.", NoSeries.Code);
        TransportReasonCode.Insert(true);
        exit(TransportReasonCode.Code)
    end;

    local procedure FindItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20]; LocationCode: Code[10]; IsPositive: Boolean)
    begin
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Location Code", LocationCode);
        ItemLedgerEntry.SetRange(Positive, IsPositive);
        ItemLedgerEntry.FindFirst();
    end;

    local procedure FindPurchaseHeader(var PurchaseHeader: Record "Purchase Header"; BuyFromVendorNo: Code[20]; SubcontractingOrder: Boolean)
    begin
        PurchaseHeader.CalcFields("Subcontracting Order");
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.SetRange("Buy-from Vendor No.", BuyFromVendorNo);
        PurchaseHeader.SetRange("Subcontracting Order", SubcontractingOrder);
        PurchaseHeader.FindFirst();
    end;

    local procedure FindPurchaseLine(var PurchaseLine: Record "Purchase Line"; DocumentNo: Code[20])
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.FindFirst();
    end;

    local procedure FindSubcontractingProdOrderNo(VendorNo: Code[20]): Code[20]
    var
        PurchaseLine: Record "Purchase Line";
        DummyProductionOrder: Record "Production Order";
    begin
        FindPurchaseLine(PurchaseLine, GetSubcontractingOrderNo(VendorNo));
        exit(GetProductionOrderNo(DummyProductionOrder.Status::Released, PurchaseLine."No."));
    end;

    local procedure FindTransferHeader(var TransferHeader: Record "Transfer Header"; TransferFromCode: Code[20])
    begin
        TransferHeader.SetRange("Transfer-from Code", TransferFromCode);
        TransferHeader.FindFirst();
    end;

    local procedure FindTransferLine(var TransferLine: Record "Transfer Line"; VendorNo: Code[20])
    var
        TransferHeader: Record "Transfer Header";
    begin
        TransferHeader.SetRange("Source No.", VendorNo);
        TransferHeader.FindFirst();
        TransferLine.SetRange("Document No.", TransferHeader."No.");
        TransferLine.FindFirst();
    end;

    local procedure FindTransferLineByItemNo(var TransferLine: Record "Transfer Line"; TransferHeaderNo: Code[20]; ItemNo: Code[20])
    begin
        TransferLine.SetRange("Document No.", TransferHeaderNo);
        TransferLine.SetRange("Item No.", ItemNo);
        TransferLine.FindFirst();
    end;

    local procedure GetProductionOrderNo(Status: Enum "Production Order Status"; SourceNo: Code[20]): Code[20]
    var
        ProductionOrder: Record "Production Order";
    begin
        ProductionOrder.SetRange(Status, Status);
        ProductionOrder.SetRange("Source Type", ProductionOrder."Source Type"::Item);
        ProductionOrder.SetRange("Source No.", SourceNo);
        ProductionOrder.FindFirst();
        exit(ProductionOrder."No.");
    end;

    local procedure GetSubcontractingOrderNo(BuyFromVendorNo: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        FindPurchaseHeader(PurchaseHeader, BuyFromVendorNo, true);  // True for Subcontracting Order.
        exit(PurchaseHeader."No.");
    end;

    local procedure MockSubcontractingTransferOrder(var TransferHeader: Record "Transfer Header"; FromLocationCode: Code[10]; ToLocationCode: Code[10]; InTransitCode: Code[10]; ItemNo: Code[20])
    var
        TransferLine: Record "Transfer Line";
    begin
        LibraryInventory.CreateTransferHeader(TransferHeader, FromLocationCode, ToLocationCode, InTransitCode);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, ItemNo, LibraryRandom.RandDec(100, 2));
        TransferLine."Prod. Order No." := LibraryUtility.GenerateGUID();
        TransferLine.Modify(true);
    end;

    local procedure PostSubcontractingOrder(VendorNo: Code[20]; VendorInvoiceNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        UpdateSubcontractingHeader(PurchaseHeader, VendorNo, VendorInvoiceNo);
        UpdateSubcontractingOrderLines(PurchaseHeader."No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure PostSubcontractingOrderWithPartialReceive(VendorNo: Code[20]; VendorInvoiceNo: Code[20]; var RemainQty: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        UpdateSubcontractingHeader(PurchaseHeader, VendorNo, VendorInvoiceNo);
        UpdateSubcontractingOrderLinesForQtyToReceive(PurchaseHeader."No.", RemainQty);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
    end;

    local procedure ReceivePurchaseOrderForChildItem(BuyFromVendorNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        FindPurchaseHeader(PurchaseHeader, BuyFromVendorNo, false);  // True for Subcontracting Order.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);  // True for Receive and False for Invoice.
    end;

    local procedure UpdateChildItem(ProductionBOMNo: Code[20]) ItemFilter: Text[30]
    var
        Item: Record Item;
        ProductionBOMLine: Record "Production BOM Line";
    begin
        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMNo);
        ProductionBOMLine.SetRange(Type, ProductionBOMLine.Type::Item);
        ProductionBOMLine.FindSet();
        repeat
            Item.Get(ProductionBOMLine."No.");
            Item.Validate("Reordering Policy", Item."Reordering Policy"::Order);
            Item.Modify(true);
            ItemFilter += '|' + ProductionBOMLine."No."
        until ProductionBOMLine.Next() = 0;
    end;

    local procedure UpdateItemJournalLine(ItemJournalBatch: Record "Item Journal Batch"; LocationCode: Code[10])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.FindSet();
        repeat
            ItemJournalLine.Validate("Location Code", LocationCode);
            ItemJournalLine.Modify(true);
        until ItemJournalLine.Next() = 0;
    end;

    local procedure UpdateItemVendorNoOnPlanningWorksheet(ItemNo: Code[20]): Code[20]
    var
        ItemVendor: Record "Item Vendor";
        RequisitionLine: Record "Requisition Line";
    begin
        // Update child item only.
        ItemVendor.SetFilter("Item No.", ItemNo);
        ItemVendor.FindFirst();
        RequisitionLine.SetFilter("Ref. Order Type", RefOrderTypeTxt);  // Required for update child item only.
        RequisitionLine.FindSet();
        repeat
            RequisitionLine.Validate("Vendor No.", ItemVendor."Vendor No.");
            RequisitionLine.Modify(true);
        until RequisitionLine.Next() = 0;
        exit(ItemVendor."Vendor No.");
    end;

    local procedure UpdateLocationOnSubcontractingOrder(VendorNo: Code[20]; LocationCode: Code[10])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, GetSubcontractingOrderNo(VendorNo));
        PurchaseHeader.Validate("Location Code", LocationCode);
        PurchaseHeader.Modify(true);
    end;

    local procedure UpdatePlanningRequisitionLine(ItemFilter: Text[50])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        // Update FG and child items.
        RequisitionLine.SetFilter("No.", ItemFilter);
        RequisitionLine.FindSet();
        repeat
            RequisitionLine.Validate("Accept Action Message", true);
            RequisitionLine.Modify(true);
        until RequisitionLine.Next() = 0;
    end;

    local procedure UpdateSubcontractingHeader(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; VendorInvoiceNo: Code[20])
    begin
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, GetSubcontractingOrderNo(VendorNo));
        PurchaseHeader.Validate("Vendor Invoice No.", VendorInvoiceNo);
        PurchaseHeader.Modify(true);
    end;

    local procedure UpdateSubcontractingOrder(VendorNo: Code[20]; ResponsibilityCenterCode: Code[10]; CurrencyCode: Code[10]; BuyFromVendorNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, GetSubcontractingOrderNo(VendorNo));
        PurchaseHeader.Validate("Responsibility Center", ResponsibilityCenterCode);
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Validate("Buy-from Vendor No.", BuyFromVendorNo);
        PurchaseHeader.Modify(true);
    end;

    local procedure UpdateSubcontractingOrderLines(DocumentNo: Code[20])
    var
        GeneralPostingSetup: Record "General Posting Setup";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryERM.FindGeneralPostingSetupInvtFull(GeneralPostingSetup);
        FindPurchaseLine(PurchaseLine, DocumentNo);
        PurchaseLine.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateSubcontractingOrderLinesForQtyToReceive(DocumentNo: Code[20]; var RemainQty: Decimal)
    var
        GeneralPostingSetup: Record "General Posting Setup";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryERM.FindGeneralPostingSetupInvtFull(GeneralPostingSetup);
        FindPurchaseLine(PurchaseLine, DocumentNo);
        PurchaseLine.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        PurchaseLine.Validate("Qty. to Receive", PurchaseLine."Qty. to Receive" / 2);
        PurchaseLine.Modify(true);
        RemainQty := PurchaseLine."Qty. to Receive";
    end;

    local procedure UpdateTransportReasonCodeInSubcontractingTransferHeader(var SubcontractingTransferHeader: Record "Transfer Header"; TransferFromCode: Code[20]; TransferToCode: Code[20]; TransportReasonCode: Code[20])
    begin
        SubcontractingTransferHeader.SetRange("Transfer-from Code", TransferFromCode);
        SubcontractingTransferHeader.SetRange("Transfer-to Code", TransferToCode);
        SubcontractingTransferHeader.FindFirst();
        SubcontractingTransferHeader.Validate("Transport Reason Code", TransportReasonCode);
        SubcontractingTransferHeader.Modify(true);
    end;

    local procedure VerifyItemLedgerEntry(ItemNo: Code[20]; LocationCode: Code[10])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ProductionOrder: Record "Production Order";
    begin
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Consumption);
        ItemLedgerEntry.SetRange("Location Code", LocationCode);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField("Order Type", ItemLedgerEntry."Order Type"::Production);
        ItemLedgerEntry.TestField("Order No.", GetProductionOrderNo(ProductionOrder.Status::Released, ItemNo));
    end;

    local procedure VerifyNoOnTransferShipmentHeader(TransferOrderNo: Code[20]; TransferShipmentHeaderNo: Code[20]; TransferShipmentHeaderNoSeries: Code[20])
    var
        TransferShipmentHeader: Record "Transfer Shipment Header";
    begin
        TransferShipmentHeader.SetRange("Transfer Order No.", TransferOrderNo);
        TransferShipmentHeader.FindFirst();
        TransferShipmentHeader.TestField("No.", TransferShipmentHeaderNo);
        TransferShipmentHeader.TestField("No. Series", TransferShipmentHeaderNoSeries);
    end;

    local procedure VerifyNoOnTransferReceiptHeader(TransferOrderNo: Code[20]; TransferReceiptHeaderNo: Code[20]; TransferReceiptHeaderNoSeries: Code[20])
    var
        TransferReceiptHeader: Record "Transfer Receipt Header";
    begin
        TransferReceiptHeader.SetRange("Transfer Order No.", TransferOrderNo);
        TransferReceiptHeader.FindFirst();
        TransferReceiptHeader.TestField("No.", TransferReceiptHeaderNo);
        TransferReceiptHeader.TestField("No. Series", TransferReceiptHeaderNoSeries);
    end;

    local procedure VerifyWarehouseInventory(Item: Record Item; LocationCode: Code[10]; Qty: Decimal)
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        Item.SetRange("Location Filter", LocationCode);
        Item.CalcFields(Inventory);
        Item.TestField(Inventory, Qty);

        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetRange("Location Code", LocationCode);
        WarehouseEntry.CalcSums(Quantity);
        WarehouseEntry.TestField(Quantity, Qty);
    end;

    local procedure VerifyShippedQty(var SubcontractingTransferHeader: Record "Transfer Header")
    var
        SubcontractingTransferLine: Record "Transfer Line";
    begin
        SubcontractingTransferLine.SetRange("Document No.", SubcontractingTransferHeader."No.");
        SubcontractingTransferLine.SetRange("WIP Item", true);
        SubcontractingTransferLine.FindFirst();
        Assert.AreEqual(SubcontractingTransferLine."WIP Qty. Shipped", SubcontractingTransferLine."WIP Quantity", NotShippedQtyForWIPItemErr);
        Assert.AreEqual(SubcontractingTransferLine."WIP Qty. To Ship", 0, NotShippedQtyForWIPItemErr);
    end;

    local procedure FindCapacityLedgerEntry(var CapacityLedgerEntry: Record "Capacity Ledger Entry"; WorkCenterNo: Code[20])
    begin
        CapacityLedgerEntry.SetRange("Work Center No.", WorkCenterNo);
        CapacityLedgerEntry.FindFirst();
    end;

    local procedure CreateItemsSetup(var Item: Record Item; var Item2: Record Item; QuantityPer: Decimal)
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        LibraryInventory.CreateItem(Item2);

        CreateCertifiedProductionBOM(ProductionBOMHeader, Item2, QuantityPer);
        UpdateProductionItem(Item, ProductionBOMHeader."No.");
    end;

    local procedure CreateCertifiedProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; Item: Record Item; QuantityPer: Decimal)
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item."No.", QuantityPer);
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);
    end;

    local procedure UpdateProductionItem(var Item: Record Item; ProductionBOMNo: Code[20])
    begin
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Production BOM No.", ProductionBOMNo);
        Item.Modify(true);
    end;

    local procedure CreateAndRefreshReleasedProductionOrder(var ProductionOrder: Record "Production Order"; SourceNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; BinCode: Code[20])
    begin
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, SourceNo, Quantity, LocationCode, BinCode);
    end;

    local procedure CreateAndRefreshProductionOrder(var ProductionOrder: Record "Production Order"; Status: Enum "Production Order Status"; SourceNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; BinCode: Code[20])
    begin
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, Status, ProductionOrder."Source Type"::Item, SourceNo, Quantity);
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Validate("Bin Code", BinCode);
        ProductionOrder.Modify(true);

        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure FindProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProdOrderStatus: Enum "Production Order Status"; ProdOrderNo: Code[20])
    begin
        ProdOrderLine.SetRange(Status, ProdOrderStatus);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderLine.FindFirst();
    end;

    local procedure FindLastItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; InventoryOrderType: Enum "Inventory Order Type"; ProdOrderNo: Code[20]; ProdOrderLineNo: Integer; ItemLedgerEntryType: Enum "Item Ledger Entry Type")
    begin
        ItemLedgerEntry.SetRange("Order Type", InventoryOrderType);
        ItemLedgerEntry.SetRange("Order No.", ProdOrderNo);
        ItemLedgerEntry.SetRange("Order Line No.", ProdOrderLineNo);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntryType);
        ItemLedgerEntry.FindLast();
    end;

    local procedure CreateAndPostItemJournalLine(ItemNo: Code[20]; Quantity: Decimal; BinCode: Code[20]; LocationCode: Code[10])
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJournalLineWithUnitCost(ItemJournalBatch, ItemJournalLine, ItemNo, Quantity, BinCode, LocationCode, LibraryRandom.RandInt(10));
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateItemJournalLineWithUnitCost(var ItemJournalBatch: Record "Item Journal Batch"; var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; Quantity: Decimal; BinCode: Code[20]; LocationCode: Code[10]; UnitCost: Decimal)
    begin
        ItemJournalSetup(ItemJournalBatch);

        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
        ItemJournalLine.Validate("Unit Cost", UnitCost);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Modify(true);
    end;

    local procedure ItemJournalSetup(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.ItemJournalSetup(ItemJournalTemplate, ItemJournalBatch);
        ItemJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalBatch.Modify(true);
    end;

    local procedure CreateSubcontractorVendor(var Vendor: Record Vendor)
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate(Subcontractor, true);
        Vendor.Modify(true);
    end;

    local procedure CreateProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; ChildItem: Record Item)
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryInventory.CreateItem(ChildItem);
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, ChildItem."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
            ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ChildItem."No.", 1);
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure CreateRoutingWithWorkCenter(var RoutingHeader: Record "Routing Header"; WorkCenterNo: Code[20])
    var
        RoutingLine: Record "Routing Line";
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(
            RoutingHeader, RoutingLine, '', LibraryUtility.GenerateGUID(), RoutingLine.Type::"Work Center", WorkCenterNo);
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
    end;

    local procedure BlockedItem(var Item: Record Item)
    begin
        Item.Validate(Blocked, true);
        Item.Modify(true);
    end;

    local procedure GetReqWkshTemplateAndBatch(var ReqWkshName: Record "Requisition Wksh. Name")
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        ReqWkshTemplate.SetRange(Type, ReqWkshTemplate.Type::"For. Labor");
        ReqWkshTemplate.FindFirst();

        LibraryPlanning.CreateRequisitionWkshName(ReqWkshName, ReqWkshTemplate.Name);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalculatePlanningWkshRequestPageHandler(var CalculatePlanPlanWksh: TestRequestPage "Calculate Plan - Plan. Wksh.")
    var
        ItemFilter: Variant;
    begin
        LibraryVariableStorage.Dequeue(ItemFilter);
        CalculatePlanPlanWksh.MPS.SetValue(true);
        CalculatePlanPlanWksh.MRP.SetValue(true);
        CalculatePlanPlanWksh.StartingDate.SetValue(WorkDate());
        CalculatePlanPlanWksh.EndingDate.SetValue(WorkDate());
        CalculatePlanPlanWksh.Item.SetFilter("No.", ItemFilter);
        CalculatePlanPlanWksh.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CarryOutActionMsgPlanRequestPageHandler(var CarryOutActionMsgPlan: TestRequestPage "Carry Out Action Msg. - Plan.")
    var
        ProdOrderChoice: Option " ",Planned,"Firm Planned";
        PurchOrderChoice: Option " ","Make Purch. Orders";
    begin
        CarryOutActionMsgPlan.ProductionOrder.SetValue(ProdOrderChoice::"Firm Planned");
        CarryOutActionMsgPlan.PurchaseOrder.SetValue(PurchOrderChoice::"Make Purch. Orders");
        CarryOutActionMsgPlan.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CarryOutActionMsgRequisitionRequestPageHandler(var CarryOutActionMsgReq: TestRequestPage "Carry Out Action Msg. - Req.")
    begin
        CarryOutActionMsgReq.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SubcontrTransferOrderModalPageHandler(var SubcontrTransferOrder: TestPage "Subcontr. Transfer Order")
    var
        TransferHeader: Record "Transfer Header";
        LocationCode: Variant;
        OptionValue: Variant;
        OptionString: Option Open,Post;
        TransferOrderOption: Option;
    begin
        LibraryVariableStorage.Dequeue(OptionValue);  // Dequeue variable.
        TransferOrderOption := OptionValue;  // To convert Variant into Option.
        case TransferOrderOption of
            OptionString::Open:
                begin
                    LibraryVariableStorage.Dequeue(LocationCode);
                    SubcontrTransferOrder."Transfer-from Code".AssertEquals(LocationCode);
                    SubcontrTransferOrder.OK().Invoke();
                end;
            OptionString::Post:
                begin
                    TransferHeader.Get(SubcontrTransferOrder."No.".Value);
                    LibraryInventory.PostTransferHeader(TransferHeader, true, true);
                end;
        end;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        // Confirm the Message.
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    procedure PostProductionJournalHandler(var ProductionJournal: TestPage "Production Journal")
    begin
        ProductionJournal.Post.Invoke();
    end;
}
#endif
