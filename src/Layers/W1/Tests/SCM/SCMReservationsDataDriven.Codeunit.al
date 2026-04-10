codeunit 137017 "SCM Reservations Data Driven"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Reservation] [SCM]
        isInitialized := false;
    end;

    var
        TempItem: Record Item temporary;
        TempSalesLine: Record "Sales Line" temporary;
        TempSalesLine2: Record "Sales Line" temporary;
        TempSalesLine3: Record "Sales Line" temporary;
        TempProdOrderComponent: Record "Prod. Order Component" temporary;
        TempProdOrderComponent2: Record "Prod. Order Component" temporary;
        TempWhseShipmentLine: Record "Warehouse Shipment Line" temporary;
        TempWhseShipmentLine2: Record "Warehouse Shipment Line" temporary;
        TempLocation: Record Location temporary;
        LibraryUtility: Codeunit "Library - Utility";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        MultipleReservations: Integer;
        ErrNothingToHandle: Label 'Nothing to handle.';

    [Normal]
    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Reservations Data Driven");
        // Initialize setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Reservations Data Driven");

        // Setup Demonstration data.
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        isInitialized := true;
        AssignNoSeries();

        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Reservations Data Driven");
    end;

    [Normal]
    local procedure AvailableToReserve(IsDirected: Boolean; RequireShipment: Boolean; RequirePick: Boolean; BinMandatory: Boolean; NoOfPurchaseDocs: Integer)
    var
        DocumentType: Option Shipment,"Rel. Prod. Order","Int. Pick","Sales Order","Transfer Order","Rel. Prod. Order - Invt.";
        SourceDocNo: Code[20];
        WhseDocNo: Code[20];
        Log: Text[1024];
        AvailableQty: Decimal;
        ErrorCount: Integer;
    begin
        Initialize();

        // Setup
        Clear(Log);
        ErrorCount := 0;
        SetupTestData(IsDirected, RequireShipment, RequirePick, BinMandatory, NoOfPurchaseDocs);

        TempItem.FindSet();
        repeat
            AvailableQty := GetExpectedAvailableQty(DocumentType, SourceDocNo, WhseDocNo, TempItem."No.");
            // Action
            ReserveFinalDemand(DocumentType, SourceDocNo, AvailableQty);

            // Verification
            asserterror
            begin
                VerifyReservations(DocumentType, SourceDocNo, AvailableQty);
                Error('');
            end;
            if GetLastErrorText <> '' then begin
                ErrorCount += 1;
                Log := CopyStr(Log + CopyStr(GetLastErrorText, 1, 25) + '||', 1, 1000);
            end;
            ClearLastError();
        until TempItem.Next() = 0;

        Assert.IsTrue(StrLen(Log) = 0, Format(ErrorCount) + ' error(s):' + Log);

        // Tear Down
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSSingleReservations()
    begin
        AvailableToReserve(true, true, true, true, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WMSMultipleReservations()
    begin
        AvailableToReserve(true, true, true, true, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NonWMS()
    begin
        AvailableToReserve(false, true, true, false, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure Inventory()
    begin
        AvailableToReserve(false, false, true, false, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NonWMSBin()
    begin
        AvailableToReserve(false, true, true, true, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure InventoryBin()
    begin
        AvailableToReserve(false, false, true, true, 1);
    end;

    [Normal]
    local procedure ProcessFirstDemand(DocumentType: Option Shipment,"Rel. Prod. Order","Int. Pick","Sales Order","Transfer Order","Rel. Prod. Order - Invt."; ItemNo: Code[20]; LocationCode: Code[10]; Qty: Decimal; QtyToReserve: Decimal; QtyToHandle: Decimal)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        WhseShipmentLine: Record "Warehouse Shipment Line";
        WhseActivityLine: Record "Warehouse Activity Line";
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        Location: Record Location;
        BinContent: Record "Bin Content";
        Bin: Record Bin;
        BinCode: Code[20];
        ZoneCode: Code[10];
    begin
        Location.Get(LocationCode);
        case DocumentType of
            DocumentType::Shipment:
                begin
                    CreateReserveSalesOrder(SalesHeader, SalesLine, ItemNo, LocationCode, Qty, QtyToReserve);
                    LibrarySales.ReleaseSalesDocument(SalesHeader);
                    LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
                    WhseShipmentLine.SetRange("Source Document", WhseShipmentLine."Source Document"::"Sales Order");
                    WhseShipmentLine.SetRange("Source No.", SalesHeader."No.");
                    WhseShipmentLine.FindFirst();
                    TempWhseShipmentLine := WhseShipmentLine;
                    TempWhseShipmentLine.Insert();
                    if WhseShipmentLine."Bin Code" = '' then begin
                        GetZoneAndBin(ZoneCode, BinCode, LocationCode, ItemNo, false);
                        if BinCode <> '' then
                            WhseShipmentLine.Validate("Bin Code", BinCode);
                    end;
                    WhseShipmentLine.Modify(true);
                    WhseShipmentHeader.Get(WhseShipmentLine."No.");
                    BinContent.SetRange("Location Code", LocationCode);
                    BinContent.SetRange("Item No.", ItemNo);
                    BinContent.SetFilter("Bin Code", '<>%1', WhseShipmentLine."Bin Code");
                    if Location."Bin Mandatory" and
                       (BinContent.Count = 0)
                    then begin // Item exists in the same bin as specified on the warehouse shipment line.
                        asserterror LibraryWarehouse.CreatePick(WhseShipmentHeader);
                        Assert.IsTrue(StrPos(GetLastErrorText, ErrNothingToHandle) > 0,
                          'Creating picks with same bin on Take & Place lines not allowed');
                        ClearLastError();
                        Bin.SetRange("Location Code", LocationCode);
                        Bin.SetFilter(Code, '<>%1', WhseShipmentLine."Bin Code");
                        Bin.FindFirst();
                        WhseShipmentHeader.Get(WhseShipmentLine."No.");
                        LibraryWarehouse.ReopenWhseShipment(WhseShipmentHeader);
                        WhseShipmentLine.Validate("Bin Code", Bin.Code);
                        WhseShipmentLine.Modify(true);
                    end;
                    LibraryWarehouse.CreatePick(WhseShipmentHeader);
                    RegisterWhseActivity(
                      WhseActivityLine."Activity Type"::Pick, WhseActivityLine."Source Document"::"Sales Order",
                      WhseActivityLine."Whse. Document Type"::Shipment, SalesHeader."No.", WhseShipmentHeader."No.", '', '', QtyToHandle);
                end;
            DocumentType::"Sales Order":
                begin
                    CreateReserveSalesOrder(SalesHeader, SalesLine, ItemNo, LocationCode, Qty, QtyToReserve);
                    LibrarySales.ReleaseSalesDocument(SalesHeader);
                    TempSalesLine := SalesLine;
                    TempSalesLine.Insert();
                    CreateInvtPutPick(WhseActivityLine."Source Document"::"Sales Order", SalesHeader."No.");
                    RegisterWhseActivity(
                      WhseActivityLine."Activity Type"::"Invt. Pick", WhseActivityLine."Source Document"::"Sales Order",
                      WhseActivityLine."Whse. Document Type"::" ", SalesHeader."No.", '', '', '', QtyToHandle);
                end;
            DocumentType::"Rel. Prod. Order":
                begin
                    CreateReserveProdOrder(ProductionOrder, LocationCode, ItemNo, Qty, QtyToReserve);
                    ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
                    ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
                    ProdOrderComponent.SetRange("Item No.", ItemNo);
                    ProdOrderComponent.FindFirst();
                    TempProdOrderComponent := ProdOrderComponent;
                    TempProdOrderComponent.Insert();
                    ProductionOrder.SetHideValidationDialog(true);
                    ProductionOrder.CreatePick(UserId, 0, false, false, false);
                    if not Location."Directed Put-away and Pick" then
                        GetZoneAndBin(ZoneCode, BinCode, LocationCode, ItemNo, false)
                    else
                        BinCode := '';
                    RegisterWhseActivity(
                      WhseActivityLine."Activity Type"::Pick, WhseActivityLine."Source Document"::"Prod. Consumption",
                      WhseActivityLine."Whse. Document Type"::Production, ProductionOrder."No.", ProductionOrder."No.", '', BinCode, QtyToHandle);
                end;
            DocumentType::"Rel. Prod. Order - Invt.":
                begin
                    CreateReserveProdOrder(ProductionOrder, LocationCode, ItemNo, Qty, QtyToReserve);
                    ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
                    ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
                    ProdOrderComponent.SetRange("Item No.", ItemNo);
                    ProdOrderComponent.FindFirst();
                    TempProdOrderComponent := ProdOrderComponent;
                    TempProdOrderComponent.Insert();
                    CreateInvtPutPick(WhseActivityLine."Source Document"::"Prod. Consumption", ProductionOrder."No.");
                    RegisterWhseActivity(
                      WhseActivityLine."Activity Type"::"Invt. Pick", WhseActivityLine."Source Document"::"Prod. Consumption",
                      WhseActivityLine."Whse. Document Type"::" ", ProductionOrder."No.", '', '', '', QtyToHandle);
                end;
        end
    end;

    [Normal]
    local procedure ProcessFinalDemand(DocumentType: Option Shipment,"Rel. Prod. Order","Int. Pick","Sales Order","Transfer Order","Rel. Prod. Order - Invt."; ItemNo: Code[20]; LocationCode: Code[10]; Qty: Decimal)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseShipmentLine: Record "Warehouse Shipment Line";
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        ZoneCode: Code[10];
        BinCode: Code[20];
    begin
        case DocumentType of
            DocumentType::Shipment:
                begin
                    CreateReserveSalesOrder(SalesHeader, SalesLine, ItemNo, LocationCode, Qty, 0);
                    LibrarySales.ReleaseSalesDocument(SalesHeader);
                    LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
                    WhseShipmentLine.SetRange("Source Document", WhseShipmentLine."Source Document"::"Sales Order");
                    WhseShipmentLine.SetRange("Source No.", SalesHeader."No.");
                    WhseShipmentLine.FindFirst();
                    TempWhseShipmentLine2 := WhseShipmentLine;
                    TempWhseShipmentLine2.Insert();
                    if WhseShipmentLine."Bin Code" = '' then begin
                        GetZoneAndBin(ZoneCode, BinCode, LocationCode, ItemNo, false);
                        if BinCode <> '' then
                            WhseShipmentLine."Bin Code" := BinCode;
                    end;
                    WhseShipmentLine.Modify(true);
                    WhseShipmentHeader.Get(WhseShipmentLine."No.");
                end;
            DocumentType::"Sales Order":
                begin
                    CreateReserveSalesOrder(SalesHeader, SalesLine, ItemNo, LocationCode, Qty, 0);
                    LibrarySales.ReleaseSalesDocument(SalesHeader);
                    TempSalesLine3 := SalesLine;
                    TempSalesLine3.Insert();
                end;
            DocumentType::"Rel. Prod. Order", DocumentType::"Rel. Prod. Order - Invt.":
                begin
                    CreateReserveProdOrder(ProductionOrder, LocationCode, ItemNo, Qty, 0);
                    ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
                    ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
                    ProdOrderComponent.SetRange("Item No.", ItemNo);
                    ProdOrderComponent.FindFirst();
                    TempProdOrderComponent2 := ProdOrderComponent;
                    TempProdOrderComponent2.Insert();
                end;
        end;
    end;

    [Normal]
    local procedure VerifyReservations(DocumentType: Option Shipment,"Rel. Prod. Order","Int. Pick","Sales Order","Transfer Order","Rel. Prod. Order - Invt."; SourceDocHeaderNo: Code[20]; ExpectedQty: Decimal)
    var
        ProdOrderComponent: Record "Prod. Order Component";
        SalesLine: Record "Sales Line";
    begin
        case DocumentType of
            DocumentType::Shipment, DocumentType::"Sales Order":
                begin
                    SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
                    SalesLine.SetRange("Document No.", SourceDocHeaderNo);
                    SalesLine.FindFirst();
                    CheckReservation(SalesLine."No.", SalesLine."Location Code", SourceDocHeaderNo, ExpectedQty, 37);
                end;
            DocumentType::"Rel. Prod. Order", DocumentType::"Rel. Prod. Order - Invt.":
                begin
                    ProdOrderComponent.SetRange("Prod. Order No.", SourceDocHeaderNo);
                    ProdOrderComponent.SetRange(Status, ProdOrderComponent.Status::Released);
                    ProdOrderComponent.FindFirst();
                    CheckReservation(ProdOrderComponent."Item No.", ProdOrderComponent."Location Code", SourceDocHeaderNo, ExpectedQty, 5407);
                end;
        end
    end;

    [Normal]
    local procedure CheckReservation(ItemNo: Code[20]; LocationCode: Code[10]; SourceID: Code[20]; ExpectedQty: Decimal; SourceType: Integer)
    var
        ReservationEntry: Record "Reservation Entry";
        ActualQty: Decimal;
    begin
        Clear(ReservationEntry);
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.SetRange("Location Code", LocationCode);
        ReservationEntry.SetRange("Source Type", SourceType);
        ReservationEntry.SetRange("Source ID", SourceID);
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Reservation);
        ReservationEntry.SetFilter(Quantity, '<%1', 0);
        ActualQty := 0;
        if ReservationEntry.FindSet() then
            repeat
                ActualQty += Abs(ReservationEntry.Quantity);
            until ReservationEntry.Next() = 0;

        Assert.AreEqual(ExpectedQty, ActualQty, 'Wrong reserved qty. on ' + Format(SourceID))
    end;

    [Normal]
    local procedure ReserveFinalDemand(DocumentType: Option Shipment,"Rel. Prod. Order","Int. Pick","Sales Order","Transfer Order","Rel. Prod. Order - Invt."; SourceDocHeaderNo: Code[20]; AvailableQty: Decimal)
    var
        SalesLine: Record "Sales Line";
        ProdOrderComponent: Record "Prod. Order Component";
        ReservationManagement: Codeunit "Reservation Management";
        FullReservation: Boolean;
    begin
        case DocumentType of
            DocumentType::Shipment, DocumentType::"Sales Order":
                begin
                    SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
                    SalesLine.SetRange("Document No.", SourceDocHeaderNo);
                    SalesLine.FindFirst();
                    ReservationManagement.SetReservSource(SalesLine);
                    FullReservation := SalesLine.Quantity <= AvailableQty;
                    ReservationManagement.AutoReserve(FullReservation, '', SalesLine."Shipment Date",
                      Round(AvailableQty / SalesLine."Qty. per Unit of Measure", 0.00001), AvailableQty);
                    SalesLine.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
                end;
            DocumentType::"Rel. Prod. Order", DocumentType::"Rel. Prod. Order - Invt.":
                begin
                    ProdOrderComponent.SetRange("Prod. Order No.", SourceDocHeaderNo);
                    ProdOrderComponent.SetRange(Status, ProdOrderComponent.Status::Released);
                    ProdOrderComponent.FindFirst();
                    ReservationManagement.SetReservSource(ProdOrderComponent);
                    FullReservation := ProdOrderComponent."Expected Quantity" <= AvailableQty;
                    ReservationManagement.AutoReserve(FullReservation, '', ProdOrderComponent."Due Date",
                      Round(AvailableQty / ProdOrderComponent."Qty. per Unit of Measure", 0.00001), AvailableQty);
                    ProdOrderComponent.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
                end;
        end
    end;

    [Normal]
    local procedure SetupLocation(var Location: Record Location; IsDirected: Boolean; ShipmentRequired: Boolean; PickRequired: Boolean; BinMandatory: Boolean)
    var
        Bin: Record Bin;
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        WarehouseEmployee: Record "Warehouse Employee";
        BinCount: Integer;
    begin
        Location.Init();
        if not IsDirected then begin
            LibraryWarehouse.CreateLocationWMS(Location, BinMandatory, PickRequired, PickRequired, ShipmentRequired, ShipmentRequired);
            Location."Directed Put-away and Pick" := IsDirected;
            Location."Default Bin Selection" := Location."Default Bin Selection"::"Fixed Bin";
            if BinMandatory then
                for BinCount := 1 to 4 do
                    LibraryWarehouse.CreateBin(Bin, Location.Code, 'bin' + Format(BinCount), '', '');
        end
        else begin
            Location.SetRange("Directed Put-away and Pick", IsDirected);
            Location.FindFirst();
            TempLocation := Location;
            TempLocation.Insert();
        end;

        Location."Always Create Pick Line" := false;
        Location."Bin Capacity Policy" := Location."Bin Capacity Policy"::"Never Check Capacity";
        Location.Modify(true);

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Stockout Warning" := false;
        SalesReceivablesSetup."Credit Warnings" := SalesReceivablesSetup."Credit Warnings"::"No Warning";
        SalesReceivablesSetup.Modify(true);

        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
    end;

    [Normal]
    local procedure CreateReserveSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; LocationCode: Code[10]; Qty: Decimal; QtyToReserve: Decimal)
    var
        ReservationManagement: Codeunit "Reservation Management";
        FullReservation: Boolean;
    begin
        if Qty <= 0 then
            exit;

        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', ItemNo, Qty, LocationCode, 0D);

        if QtyToReserve > 0 then begin
            FullReservation := (Qty = QtyToReserve);
            ReservationManagement.SetReservSource(SalesLine);
            ReservationManagement.AutoReserve(FullReservation, '', SalesLine."Shipment Date",
              Round(QtyToReserve / SalesLine."Qty. per Unit of Measure", 0.00001), QtyToReserve);
            SalesLine.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        end;
    end;

    [Normal]
    local procedure CreateReserveProdOrder(var ProductionOrder: Record "Production Order"; LocationCode: Code[10]; ItemNo: Code[20]; Qty: Decimal; QtyToReserve: Decimal)
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        Item: Record Item;
        ProdOrderComponent: Record "Prod. Order Component";
        ReservationManagement: Codeunit "Reservation Management";
        FullReservation: Boolean;
    begin
        if Qty <= 0 then
            exit;
        LibraryManufacturing.SetComponentsAtLocation(LocationCode);
        LibraryInventory.CreateItem(Item);
        ProductionBOMLine.SetCurrentKey(Type, "No.");
        ProductionBOMLine.SetRange(Type, ProductionBOMLine.Type::Item);
        ProductionBOMLine.SetRange("No.", ItemNo);
        if not ProductionBOMLine.FindFirst() then begin
            LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");
            LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ItemNo, 1);
            ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        end
        else
            ProductionBOMHeader.Get(ProductionBOMLine."Production BOM No.");

        Item."Replenishment System" := Item."Replenishment System"::"Prod. Order";
        Item."Production BOM No." := ProductionBOMHeader."No.";
        Item.Modify(true);

        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", Qty);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, true, true, true, true, true);

        if QtyToReserve > 0 then begin
            FullReservation := (Qty >= QtyToReserve);
            ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
            ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
            ProdOrderComponent.FindFirst();
            ReservationManagement.SetReservSource(ProdOrderComponent);
            ReservationManagement.AutoReserve(FullReservation, '', ProdOrderComponent."Due Date",
              Round(QtyToReserve / ProdOrderComponent."Qty. per Unit of Measure", 0.00001), QtyToReserve);
            ProdOrderComponent.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
            Commit();
        end;
    end;

    [Normal]
    local procedure RegisterWhseActivity(ActivityType: Enum "Warehouse Activity Type"; SourceDocument: Enum "Warehouse Activity Source Document"; WhseDocType: Enum "Warehouse Activity Document Type"; SourceNo: Code[20]; WhseDocNo: Code[20]; TakeBinCode: Code[20]; PlaceBinCode: Code[20]; QtyToHandle: Decimal)
    var
        WhseActivityLine: Record "Warehouse Activity Line";
        WhseActivityHeader: Record "Warehouse Activity Header";
    begin
        Clear(WhseActivityLine);
        WhseActivityLine.Reset();
        WhseActivityLine.SetRange("Source Document", SourceDocument);
        WhseActivityLine.SetRange("Source No.", SourceNo);
        WhseActivityLine.SetRange("Whse. Document Type", WhseDocType);
        WhseActivityLine.SetRange("Whse. Document No.", WhseDocNo);
        WhseActivityLine.FindSet();

        repeat
            WhseActivityLine.Validate("Qty. to Handle", QtyToHandle);
            if (WhseActivityLine."Action Type" = WhseActivityLine."Action Type"::Take) and
               (TakeBinCode <> '')
            then
                WhseActivityLine."Bin Code" := TakeBinCode;
            if (WhseActivityLine."Action Type" = WhseActivityLine."Action Type"::Place) and
               (PlaceBinCode <> '')
            then
                WhseActivityLine."Bin Code" := PlaceBinCode;
            WhseActivityLine.Modify(true);
        until WhseActivityLine.Next() = 0;

        Clear(WhseActivityHeader);
        WhseActivityHeader.SetCurrentKey(Type, "No.");
        WhseActivityHeader.SetRange(Type, ActivityType);
        WhseActivityHeader.SetRange("No.", WhseActivityLine."No.");
        WhseActivityHeader.FindFirst();

        if QtyToHandle > 0 then
            if WhseActivityLine."Activity Type" in
               [WhseActivityLine."Activity Type"::"Invt. Put-away", WhseActivityLine."Activity Type"::"Invt. Pick"]
            then
                LibraryWarehouse.PostInventoryActivity(WhseActivityHeader, false)
            else
                LibraryWarehouse.RegisterWhseActivity(WhseActivityHeader);
    end;

    [Normal]
    local procedure CreateInvtPutPick(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    var
        WhseRequest: Record "Warehouse Request";
        CreateInvtPutAwayPickMvmt: Report "Create Invt Put-away/Pick/Mvmt";
    begin
        WhseRequest.Reset();
        WhseRequest.SetCurrentKey("Source Document", "Source No.");
        WhseRequest.SetRange("Source Document", SourceDocument);
        WhseRequest.SetRange("Source No.", SourceNo);
        CreateInvtPutAwayPickMvmt.InitializeRequest(true, true, false, false, false);
        CreateInvtPutAwayPickMvmt.SetTableView(WhseRequest);
        CreateInvtPutAwayPickMvmt.UseRequestPage := false;
        CreateInvtPutAwayPickMvmt.RunModal();
    end;

    [Normal]
    local procedure GetExpectedAvailableQty(var DocumentType: Option Shipment,"Rel. Prod. Order","Int. Pick","Sales Order","Transfer Order","Rel. Prod. Order - Invt."; var SourceDocNo: Code[20]; var WhseDocNo: Code[20]; ItemNo: Code[20]): Decimal
    var
        PurchaseLine: Record "Purchase Line";
        Location: Record Location;
        DemandQty: Decimal;
        SupplyQty: Decimal;
        RequestQty: Decimal;
    begin
        // Calculate demand qty by collecting quantities on Sales Orders, Transfer Orders, Internal Picks and Released Prod. Orders.
        // Extract request qty from last document in the scenario.
        DemandQty := 0;

        TempWhseShipmentLine.SetRange("Item No.", ItemNo);
        if TempWhseShipmentLine.FindFirst() then
            DemandQty += TempWhseShipmentLine.Quantity;

        TempWhseShipmentLine2.SetRange("Item No.", ItemNo);
        if TempWhseShipmentLine2.FindFirst() then begin
            DocumentType := DocumentType::Shipment;
            SourceDocNo := TempWhseShipmentLine2."Source No.";
            WhseDocNo := TempWhseShipmentLine2."No.";
            RequestQty := TempWhseShipmentLine2.Quantity;
        end;
        TempSalesLine.SetRange("No.", ItemNo);
        if TempSalesLine.FindFirst() then
            DemandQty += TempSalesLine.Quantity;

        TempSalesLine2.SetRange("No.", ItemNo);
        if TempSalesLine2.FindFirst() then begin
            TempSalesLine2.CalcFields("Reserved Quantity");
            DemandQty += TempSalesLine2."Reserved Quantity";
        end;

        TempSalesLine3.SetRange("No.", ItemNo);
        if TempSalesLine3.FindFirst() then begin
            DocumentType := DocumentType::"Sales Order";
            SourceDocNo := TempSalesLine3."Document No.";
            WhseDocNo := '';
            RequestQty := TempSalesLine3.Quantity;
        end;

        TempProdOrderComponent.SetRange("Item No.", ItemNo);
        if TempProdOrderComponent.FindFirst() then
            DemandQty += TempProdOrderComponent."Expected Quantity";

        TempProdOrderComponent2.SetRange("Item No.", ItemNo);
        if TempProdOrderComponent2.FindFirst() then begin
            Location.Get(TempProdOrderComponent2."Location Code");
            if Location."Require Shipment" then
                DocumentType := DocumentType::"Rel. Prod. Order"
            else
                DocumentType := DocumentType::"Rel. Prod. Order - Invt.";
            WhseDocNo := TempProdOrderComponent2."Prod. Order No.";
            SourceDocNo := TempProdOrderComponent2."Prod. Order No.";
            RequestQty := TempProdOrderComponent2."Expected Quantity";
        end;

        // Calculate supply based on received Purchase Orders.
        SupplyQty := 0;
        PurchaseLine.SetRange("No.", ItemNo);
        PurchaseLine.FindSet();
        repeat
            Location.Get(PurchaseLine."Location Code");
            SupplyQty += PurchaseLine."Quantity Received";
        until PurchaseLine.Next() = 0;

        // Expected qty to pick is minimum betqeen requested qty for the last document, and available qty to pick.
        if SupplyQty - DemandQty >= 0 then
            exit(GetMin(SupplyQty - DemandQty, RequestQty));
        exit(0);
    end;

    [Normal]
    local procedure SetupTestData(IsDirected: Boolean; RequireShip: Boolean; RequirePick: Boolean; BinMandatory: Boolean; MultipleResFactor: Integer)
    var
        Location: Record Location;
        DocumentType: Option Shipment,"Rel. Prod. Order","Int. Pick","Sales Order","Transfer Order","Rel. Prod. Order - Invt.";
    begin
        // Test Data creation.
        // Parameters:
        // 1. Location for test.
        // 2. First document type.
        // 3. Final document type.
        // 4. Is the put-away partial?
        // 5. Total Qty on purchase order(s).
        // 6. Qty on first document.
        // 7. Qty to reserve on first document.
        // 8. Qty to handle on the first pick generated.
        // 9. Qty on reserved sales order.
        // 10. Qty to reserve on the sales order.
        // 11. Qty on final document.
        // Available Qty to Reserve = Qty put-away from Purchase Order(s) - Qty on first document - Qty reserved on sales order.

        TempItem.DeleteAll();
        TempLocation.DeleteAll();
        TempWhseShipmentLine.DeleteAll();
        TempWhseShipmentLine2.DeleteAll();
        TempSalesLine.DeleteAll();
        TempSalesLine2.DeleteAll();
        TempSalesLine3.DeleteAll();
        TempProdOrderComponent.DeleteAll();
        TempProdOrderComponent2.DeleteAll();
        MultipleReservations := MultipleResFactor;

        SetupLocation(Location, IsDirected, RequireShip, RequirePick, BinMandatory);
        if IsDirected then begin
            // TDS Scenarios.
            SetupTestDataLine(Location, DocumentType::Shipment, DocumentType::Shipment, false, 10, 5, 5, 2, 0, 0, 5);  // Line 1.
            SetupTestDataLine(Location, DocumentType::Shipment, DocumentType::Shipment, true, 10, 5, 5, 2, 0, 0, 5);
            SetupTestDataLine(Location, DocumentType::Shipment, DocumentType::Shipment, true, 10, 9, 7, 1, 0, 0, 3);
            // Bug 166592.
            SetupTestDataLine(Location, DocumentType::Shipment, DocumentType::Shipment, false, 10, 9, 7, 1, 1, 1, 3);
            SetupTestDataLine(Location, DocumentType::Shipment, DocumentType::Shipment, true, 10, 7, 7, 7, 0, 0, 3);
            SetupTestDataLine(Location, DocumentType::Shipment, DocumentType::Shipment, false, 10, 7, 7, 1, 2, 2, 1);
            SetupTestDataLine(Location, DocumentType::Shipment, DocumentType::Shipment, true, 10, 3, 2, 0, 0, 0, 8);
            SetupTestDataLine(Location, DocumentType::Shipment, DocumentType::Shipment, true, 10, 3, 2, 0, 4, 4, 10);
            SetupTestDataLine(Location, DocumentType::Shipment, DocumentType::Shipment, true, 10, 3, 3, 0, 7, 7, 3);
            SetupTestDataLine(Location, DocumentType::Shipment, DocumentType::Shipment, false, 10, 5, 5, 5, 0, 0, 4);
            SetupTestDataLine(Location, DocumentType::Shipment, DocumentType::Shipment, true, 10, 5, 5, 2, 1, 1, 3);
        end;

        if (not IsDirected) and RequireShip then begin
            SetupTestDataLine(Location, DocumentType::Shipment, DocumentType::Shipment, false, 10, 6, 6, 2, 1, 1, 5);   // Line 1.
            SetupTestDataLine(Location, DocumentType::Shipment, DocumentType::Shipment, false, 10, 6, 2, 0, 1, 1, 3);
            SetupTestDataLine(Location, DocumentType::Shipment, DocumentType::Shipment, false, 10, 6, 2, 0, 0, 0, 4);
            SetupTestDataLine(Location, DocumentType::Shipment, DocumentType::Shipment, false, 10, 6, 6, 2, 1, 1, 4);
            SetupTestDataLine(Location, DocumentType::Shipment, DocumentType::Shipment, false, 10, 6, 2, 6, 0, 0, 4);
            SetupTestDataLine(Location, DocumentType::Shipment, DocumentType::Shipment, false, 10, 6, 6, 0, 1, 1, 4);
            // Bug 166592.
            SetupTestDataLine(Location, DocumentType::Shipment, DocumentType::Shipment, false, 10, 9, 3, 2, 1, 1, 5);
        end;

        if (not IsDirected) and (not RequireShip) and RequirePick then begin
            SetupTestDataLine(Location, DocumentType::"Sales Order", DocumentType::"Sales Order", true, 10, 5, 5, 2, 1, 1, 3);  // Line 1.
                                                                                                                                // Bug 166592.
            SetupTestDataLine(Location, DocumentType::"Sales Order", DocumentType::"Sales Order", true, 10, 9, 2, 0, 0, 0, 5);
            SetupTestDataLine(Location, DocumentType::"Sales Order", DocumentType::"Sales Order", true, 10, 5, 2, 0, 1, 1, 3);
        end;
        Commit();
    end;

    [Normal]
    local procedure SetupTestDataLine(Location: Record Location; FirstDocumentType: Option Shipment,"Rel. Prod. Order","Int. Pick","Sales Order","Transfer Order","Rel. Prod. Order - Invt."; FinalDocumentType: Option Shipment,"Rel. Prod. Order","Int. Pick","Sales Order","Transfer Order","Rel. Prod. Order - Invt."; PartialReceive: Boolean; SuppliedQty: Decimal; FirstDocQty: Decimal; FirstDocQtyReserved: Decimal; FirstDocQtyToHandle: Decimal; SecondDocQty: Decimal; SecondDocQtyReserved: Decimal; FinalDocQty: Decimal)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        AllocatedQty: Decimal;
        DocCount: Integer;
    begin
        LibraryInventory.CreateItem(Item);
        TempItem := Item;
        TempItem.Insert();

        AllocatedQty := 0;
        for DocCount := 1 to MultipleReservations do begin
            ProcessPurchaseOrder(Item."No.", Location.Code, PartialReceive and (DocCount = 1), Round(SuppliedQty / MultipleReservations, 1));
            AllocatedQty += Round(SuppliedQty / MultipleReservations, 1);
        end;
        if SuppliedQty - AllocatedQty > 0 then
            ProcessPurchaseOrder(Item."No.", Location.Code, false, SuppliedQty - AllocatedQty);

        ProcessFirstDemand(FirstDocumentType, Item."No.", Location.Code, FirstDocQty, FirstDocQtyReserved, FirstDocQtyToHandle);
        CreateReserveSalesOrder(SalesHeader, SalesLine, Item."No.", Location.Code, SecondDocQty, SecondDocQtyReserved);
        if SecondDocQty > 0 then begin
            TempSalesLine2 := SalesLine;
            TempSalesLine2.Insert();
        end;
        ProcessFinalDemand(FinalDocumentType, Item."No.", Location.Code, FinalDocQty);
    end;

    [Normal]
    local procedure PutAwayQty(PartialReceive: Boolean; QtyReceived: Decimal): Decimal
    begin
        if PartialReceive then
            exit(QtyReceived - 1);
        exit(QtyReceived);
    end;

    [Normal]
    local procedure GetMin(FirstQty: Decimal; SecondQty: Decimal): Decimal
    begin
        if FirstQty < SecondQty then
            exit(FirstQty);
        exit(SecondQty);
    end;

    [Normal]
    local procedure AssignNoSeries()
    var
        InventorySetup: Record "Inventory Setup";
        WarehouseSetup: Record "Warehouse Setup";
        ManufacturingSetup: Record "Manufacturing Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        InventorySetup.Get();
        InventorySetup."Transfer Order Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        InventorySetup."Inventory Put-away Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        InventorySetup."Inventory Pick Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        InventorySetup."Posted Transfer Shpt. Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        InventorySetup.Modify(true);

        WarehouseSetup.Get();
        WarehouseSetup."Whse. Receipt Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        WarehouseSetup."Whse. Put-away Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        WarehouseSetup."Whse. Pick Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        WarehouseSetup."Whse. Ship Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        WarehouseSetup."Whse. Internal Pick Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        WarehouseSetup.Modify(true);

        ManufacturingSetup.Get();
        ManufacturingSetup."Released Order Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        ManufacturingSetup."Production BOM Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        ManufacturingSetup.Modify(true);

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Customer Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        SalesReceivablesSetup."Order Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        SalesReceivablesSetup.Modify(true);

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Order Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        PurchasesPayablesSetup."Posted Receipt Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        PurchasesPayablesSetup.Modify(true);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    local procedure TearDown()
    var
        Location: Record Location;
    begin
        TempLocation.SetRange("Directed Put-away and Pick", true);
        if TempLocation.FindFirst() then begin
            Location.Get(TempLocation.Code);
            Location."Always Create Pick Line" := TempLocation."Always Create Pick Line";
            Location."Bin Capacity Policy" := TempLocation."Bin Capacity Policy";
            Location.Modify(true);
        end;
        LibraryManufacturing.SetComponentsAtLocation('');
    end;

    [Normal]
    local procedure ProcessPurchaseOrder(ItemNo: Code[20]; LocationCode: Code[10]; PartialReceive: Boolean; Quantity: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WhseReceiptLine: Record "Warehouse Receipt Line";
        WhseActivityLine: Record "Warehouse Activity Line";
        PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header";
        Location: Record Location;
        WhsePostReceipt: Codeunit "Whse.-Post Receipt";
        BinCode: Code[20];
        ZoneCode: Code[10];
    begin
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', ItemNo, Quantity, LocationCode, 0D);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        Location.Get(LocationCode);
        if Location."Directed Put-away and Pick" or Location."Require Receive" then begin
            LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
            WhseReceiptLine.SetRange("Source Document", WhseReceiptLine."Source Document"::"Purchase Order");
            WhseReceiptLine.SetRange("Source No.", PurchaseHeader."No.");
            WhseReceiptLine.FindFirst();

            if Location."Bin Mandatory" and (WhseReceiptLine."Bin Code" = '') then begin
                GetZoneAndBin(ZoneCode, BinCode, Location.Code, ItemNo, false);
                WhseReceiptLine."Bin Code" := BinCode;
                WhseReceiptLine.Modify(true);
            end;

            WhsePostReceipt.Run(WhseReceiptLine);
            PostedWhseReceiptHeader.SetCurrentKey("Whse. Receipt No.");
            PostedWhseReceiptHeader.SetRange("Whse. Receipt No.", WhseReceiptLine."No.");
            PostedWhseReceiptHeader.FindFirst();

            if Location."Bin Mandatory" then
                GetZoneAndBin(ZoneCode, BinCode, Location.Code, '', Location."Directed Put-away and Pick")
            else
                BinCode := '';
            RegisterWhseActivity(
              WhseActivityLine."Activity Type"::"Put-away", WhseActivityLine."Source Document"::"Purchase Order",
              WhseActivityLine."Whse. Document Type"::Receipt, PurchaseHeader."No.", PostedWhseReceiptHeader."No.",
              '', BinCode, PutAwayQty(PartialReceive, WhseReceiptLine.Quantity));
        end
        else begin
            CreateInvtPutPick(WhseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
            if Location."Bin Mandatory" then
                GetZoneAndBin(ZoneCode, BinCode, Location.Code, ItemNo, false)
            else
                BinCode := '';
            RegisterWhseActivity(
              WhseActivityLine."Activity Type"::"Invt. Put-away", WhseActivityLine."Source Document"::"Purchase Order",
              WhseActivityLine."Whse. Document Type"::" ", PurchaseHeader."No.", '', '', BinCode,
              PutAwayQty(PartialReceive, Quantity));
        end;
    end;

    [Normal]
    local procedure GetZoneAndBin(var ZoneCode: Code[10]; var BinCode: Code[20]; LocationCode: Code[20]; ExcludedItem: Code[20]; CheckTypeCode: Boolean)
    var
        Bin: Record Bin;
        BinType: Record "Bin Type";
        BinContent: Record "Bin Content";
    begin
        ZoneCode := '';
        BinCode := '';

        BinType.SetRange(Pick, true);
        BinType.SetRange("Put Away", true);
        BinType.FindFirst();

        Bin.SetRange("Location Code", LocationCode);
        Bin.SetRange("Block Movement", Bin."Block Movement"::" ");
        if CheckTypeCode then
            Bin.SetRange("Bin Type Code", BinType.Code)
        else
            Bin.SetFilter("Bin Type Code", '<>%1', BinType.Code);

        if Bin.FindSet() then
            repeat
                BinContent.SetRange("Location Code", LocationCode);
                BinContent.SetRange("Bin Code", Bin.Code);
                BinContent.SetCurrentKey("Item No.");
                BinContent.SetRange("Item No.", ExcludedItem);
                if not BinContent.FindFirst() then begin
                    ZoneCode := Bin."Zone Code";
                    BinCode := Bin.Code;
                    exit;
                end;
            until Bin.Next() = 0;
    end;
}

