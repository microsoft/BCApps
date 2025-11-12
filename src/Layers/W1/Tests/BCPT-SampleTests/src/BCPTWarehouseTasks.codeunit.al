namespace System.Test.Tooling;
using Microsoft.Inventory.Transfer;
using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Setup;
using Microsoft.Inventory.Item;
using Microsoft.Warehouse.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.Inventory.Setup;
using Microsoft.Warehouse.Activity;
using Microsoft.Sales.Document;
using Microsoft.Purchases.Document;
using Microsoft.Warehouse.Structure;
using Microsoft.Inventory.Journal;
using Microsoft.Foundation.NoSeries;
using System.Tooling;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Duplicates;

codeunit 149201 "BCPT Warehouse Tasks"
{
    SingleInstance = true;

    var
        ItemJournalBatch: Record "Item Journal Batch";
        WarehouseEmployee: Record "Warehouse Employee";
        LocationBlue: Record Location;
        LocationGreen: Record Location;
        LocationOrange: Record Location;
        LocationOrange2: Record Location;
        LocationOrange3: Record Location;
        LocationWhite: Record Location;
        LocationRed: Record Location;
        LocationPink: Record Location;
        LocationIntransit: Record Location;
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        isInitialized: Boolean;

    trigger OnRun()
    var
        BCPTTestContext: Codeunit "BCPT Test Context";
    begin
        BCPTTestContext.StartScenario('TransferWhseShipment');
        TransferWhseShipment();
        BCPTTestContext.EndScenario('TransferWhseShipment');
        BCPTTestContext.UserWait();

        BCPTTestContext.StartScenario('TransferWhseCreatePick');
        TransferWhseCreatePick();
        BCPTTestContext.EndScenario('TransferWhseCreatePick');
        BCPTTestContext.UserWait();

        BCPTTestContext.StartScenario('TransferWhseReceipt');
        TransferWhseReceipt();
        BCPTTestContext.EndScenario('TransferWhseReceipt');
        BCPTTestContext.UserWait();

        BCPTTestContext.StartScenario('WhseCreateSalesOrder');
        WhseCreateSalesOrder();
        BCPTTestContext.EndScenario('WhseCreateSalesOrder');
        BCPTTestContext.UserWait();

        BCPTTestContext.StartScenario('SalesWhseShipment');
        SalesWhseShipment();
        BCPTTestContext.EndScenario('SalesWhseShipment');
        BCPTTestContext.UserWait();

        BCPTTestContext.StartScenario('SalesCreatePick');
        SalesCreatePick();
        BCPTTestContext.EndScenario('SalesCreatePick');
        BCPTTestContext.UserWait();

        BCPTTestContext.StartScenario('SalesRegisterPickPostShipment');
        SalesRegisterPickPostShipment();
        BCPTTestContext.EndScenario('SalesRegisterPickPostShipment');
        BCPTTestContext.UserWait();

        BCPTTestContext.StartScenario('WhseCreatePurchaseOrder');
        WhseCreatePurchaseOrder();
        BCPTTestContext.EndScenario('WhseCreatePurchaseOrder');
        BCPTTestContext.UserWait();

        BCPTTestContext.StartScenario('PurchaseWarehouseReceipt');
        PurchaseWarehouseReceipt();
        BCPTTestContext.EndScenario('PurchaseWarehouseReceipt');
        BCPTTestContext.UserWait();

        BCPTTestContext.StartScenario('PurchasePutAway');
        PurchasePutAway();
        BCPTTestContext.EndScenario('PurchasePutAway');
        BCPTTestContext.UserWait();

        BCPTTestContext.StartScenario('PurchaseChangeBinAndRegister');
        PurchaseChangeBinAndRegister();
        BCPTTestContext.EndScenario('PurchaseChangeBinAndRegister');
        BCPTTestContext.UserWait();

        BCPTTestContext.StartScenario('ReceiveTransferOrder');
        ReceiveTransferOrder();
        BCPTTestContext.EndScenario('ReceiveTransferOrder');
        BCPTTestContext.UserWait();
    end;

    local procedure TransferWhseShipment()
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
    begin
        // Setup : Create Item, Transfer Order.
        Initialize();
        CreateItemAddInventory(Item, LocationOrange.Code, 1);  // Value required for Bin Index.
        CreateAndRealeaseTransferOrder(
          TransferHeader, TransferLine, Item."No.", LocationOrange.Code, LocationOrange2.Code, LocationIntransit.Code);

        // Exercise: Create Warehouse Shipment from Transfer Order.
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);
    end;

    local procedure TransferWhseCreatePick()
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
    begin
        // Setup : Create Item, Transfer Order, Create Warehouse Shipment from Transfer Order and change bin code on Shipment Line.
        Initialize();
        CreateItemAddInventory(Item, LocationOrange.Code, 1);  // Value required for Bin Index.
        CreateAndRealeaseTransferOrder(TransferHeader, TransferLine, Item."No.", LocationOrange.Code, LocationOrange2.Code, LocationIntransit.Code);
        WhseShipFromTOWithNewBinCode(TransferHeader);
    end;

    local procedure TransferWhseReceipt()
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        // Setup : Create Item, Transfer Order, Create Warehouse Shipment from Transfer Order and change bin code on Shipment Line and Post
        // Warehouse Shipment.
        Initialize();
        CreateItemAddInventory(Item, LocationOrange.Code, 1);  // Value required for Bin Index.
        CreateAndRealeaseTransferOrder(
          TransferHeader, TransferLine, Item."No.", LocationOrange.Code, LocationOrange2.Code, LocationIntransit.Code);
        WhseShipFromTOWithNewBinCode(TransferHeader);
        RegisterWarehouseActivity(TransferHeader."No.", WarehouseActivityHeader.Type::Pick);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, true);

        // Exercise: Create Warehouse Receipt from Transfer Order.
        LibraryWarehouse.CreateWhseReceiptFromTO(TransferHeader);
    end;

    local procedure RegisterWarehouseActivity(SourceNo: Code[20]; Type: Enum "Warehouse Activity Type")
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        WarehouseActivityHeader.SetRange(Type, Type);
        WarehouseActivityHeader.SetRange("No.", FindWarehouseActivityNo(SourceNo, Type));
        if WarehouseActivityHeader.FindFirst() then
            LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure WhseCreateSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        BinCode: Code[20];
    begin
        // Setup : Create Item, Bin Content for the item.
        Initialize();
        BinCode := CreateItemAddInventory(Item, LocationOrange.Code, 1);  // Value required for Bin Index.

        // Exercise.
        CreateSalesOrder(SalesHeader, SalesLine, LocationOrange.Code, Item."No.", 5, WorkDate());

        // Verify: Check that Bin Code is same as Default Bin Code.
        SalesLine.TestField("Bin Code", BinCode);
    end;

    local procedure SalesWhseShipment()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        // Setup : Create Item, Bin Content for the Item and Create and Release Sales Order.
        Initialize();
        CreateItemAddInventory(Item, LocationOrange.Code, 1);  // Value required for Bin Index.
        CreateSalesOrder(SalesHeader, SalesLine, LocationOrange.Code, Item."No.", 5, WorkDate());
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // Exercise.
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
    end;

    local procedure SalesCreatePick()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        // Setup : Create Item, Bin Content for the Item and Create and Release Sales Order, Create Warehouse Shipment.
        Initialize();
        CreateItemAddInventory(Item, LocationOrange.Code, 1);  // Value required for Bin Index.
        CreateSalesOrder(SalesHeader, SalesLine, LocationOrange.Code, Item."No.", 5, WorkDate());
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        WhseShipFromSOWithNewBinCode(SalesHeader);
    end;

    local procedure SalesRegisterPickPostShipment()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        // Setup : Create Item, Bin Content for the Item and Create and Release Sales Order, Create Warehouse Shipment, Create And
        // Register Pick.
        Initialize();
        CreateItemAddInventory(Item, LocationOrange.Code, 1);  // Value required for Bin Index.
        CreateSalesOrder(SalesHeader, SalesLine, LocationOrange.Code, Item."No.", 5, WorkDate());
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        WhseShipFromSOWithNewBinCode(SalesHeader);
        RegisterWarehouseActivity(SalesHeader."No.", WarehouseActivityHeader.Type::Pick);

        // Exercise.
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, true);
    end;

    local procedure WhseCreatePurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        BinCode: Code[20];
    begin
        // Setup : Create Item, Bin Content for the item.
        Initialize();
        BinCode := CreateItemAddInventory(Item, LocationOrange.Code, 1);  // Value required for Bin Index.

        // Exercise.
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, LocationOrange.Code, Item."No.");

        // Verify: Check that Bin Code is same as Default Bin Code.
        PurchaseLine.TestField("Bin Code", BinCode);
    end;

    local procedure PurchaseWarehouseReceipt()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
    begin
        // Setup : Create Item, Bin Content for the Item and Create and Release Sales Order.
        Initialize();
        CreateItemAddInventory(Item, LocationOrange.Code, 1);  // Value required for Bin Index.

        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, LocationOrange.Code, Item."No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // Exercise:
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
    end;

    local procedure PurchasePutAway()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        Item: Record Item;
    begin
        // Setup : Create Item, Bin Content for the Item and Create and Release Sales Order.
        Initialize();
        CreateItemAddInventory(Item, LocationOrange.Code, 1);  // Value required for Bin Index.

        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, LocationOrange.Code, Item."No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        // Exercise:
        PostWarehouseReceipt(WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
    end;

    local procedure PostWarehouseReceipt(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
    begin
        WarehouseReceiptHeader.Get(FindWarehouseReceiptNo(SourceDocument, SourceNo));
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
    end;

    local procedure PurchaseChangeBinAndRegister()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        Item: Record Item;
        BinCode2: Code[20];
    begin
        // Setup : Create Item, Bin Content for the Item and Create and Release Sales Order.
        Initialize();
        CreateItemAddInventory(Item, LocationOrange.Code, 1);  // Value required for Bin Index.
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, LocationOrange.Code, Item."No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        PostWarehouseReceipt(WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");

        // Exercise: Change Bin Code on Put Away Line and Register Put Away.
        ChangeBinCodeOnActivityLine(BinCode2, PurchaseHeader."No.", LocationOrange.Code);
        RegisterWarehouseActivity(PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Put-away");
    end;

    local procedure ChangeBinCodeOnActivityLine(var BinCode: Code[20]; SourceNo: Code[20]; LocationCode: Code[10])
    var
        Bin: Record Bin;
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        LibraryWarehouse.FindBin(Bin, LocationCode, '', 2);
        BinCode := Bin.Code;
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::"Put-away", LocationCode, SourceNo,
          WarehouseActivityLine."Action Type"::Place);
        WarehouseActivityLine.Validate("Bin Code", BinCode);
        WarehouseActivityLine.Modify(true);
        Commit();
    end;

    local procedure ReceiveTransferOrder()
    begin
        Initialize();
        TransferOrderWithShipmentAndReceipt();
        Commit();
    end;

    local procedure WhseShipFromTOWithNewBinCode(TransferHeader: Record "Transfer Header")
    begin
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);
        Commit();
    end;

    local procedure TransferOrderWithShipmentAndReceipt()
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        // Setup : Create Item, Transfer Order, Create Warehouse Shipment from Transfer Order and Post Warehouse Shipment.
        CreateItemAddInventory(Item, LocationOrange.Code, 1);  // Value required for Bin Index.
        Commit();
        LibraryWarehouse.CreateTransferHeader(TransferHeader, LocationOrange.Code, LocationBlue.Code, LocationIntransit.Code);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 50);
        Commit();
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);
        Commit();
        WhseShipFromTOWithNewBinCode(TransferHeader);
        Commit();
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, LocationOrange.Code, TransferHeader."No.",
          WarehouseActivityLine."Action Type"::Take);
        RegisterWarehouseActivity(TransferHeader."No.", WarehouseActivityHeader.Type::Pick);
        Commit();

        PostWarehouseShipment(WarehouseShipmentHeader."No.");
        Commit();
    end;

    local procedure PostWarehouseShipment(No: Code[20])
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        if WarehouseShipmentHeader.Get(No) then
            LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);
        Commit();
    end;

    local procedure CreateItem(var Item: Record Item)
    var
        Vendor: Record Vendor;
    begin
        if not Vendor.Get('10000') then
            Vendor.FindFirst();
        LibraryInventory.CreateItem(Item);
        Item.Validate("Reorder Quantity", 50);  // Value Required.
        Item.Validate("Vendor No.", Vendor."No.");
        Item.Modify(true);
        Commit();
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; LocationCode: Code[10]; ItemNo: Code[20])
    var
        i: Integer;
    begin
        // Create Purchase Order with One Item Line. Random values used are not important for test.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        for i := 1 to 50 do
            LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, 1);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Modify(true);
        Commit();
    end;

    local procedure CreateItemAddInventory(var Item: Record Item; LocationCode: Code[10]; BinIndex: Integer): Code[20]
    var
        Bin: Record Bin;
    begin
        LibraryWarehouse.FindBin(Bin, LocationCode, '', BinIndex);
        CreateItem(Item);
        Commit();
        UpdateItemInventory(Item."No.", LocationCode, Bin.Code, 1);
        Commit();
        exit(Bin.Code);
    end;

    local procedure UpdateItemInventory(ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.LockTable();
        InventorySetup.Get(); // semaphore
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        Commit();
    end;

    local procedure CreateAndRealeaseTransferOrder(var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line"; ItemNo: Code[20]; FromLocationCode: Code[10]; ToLocationCode: Code[10]; IntransitLocationCode: Code[10])
    var
        ToBin: Record Bin;
        i: Integer;
    begin
        LibraryWarehouse.FindBin(ToBin, ToLocationCode, '', 1);
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocationCode, ToLocationCode, IntransitLocationCode);
        for i := 1 to 50 do begin
            LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, 1);
            TransferLine.Validate("Transfer-To Bin Code", ToBin.Code);
            TransferLine.Modify(true);
        end;
        Commit();

        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);
        Commit();
    end;

    local procedure FindWarehouseActivityNo(SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type"): Code[20]
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        if WarehouseActivityLine.FindFirst() then
            exit(WarehouseActivityLine."No.");
        exit('');
    end;

    local procedure FindWarehouseReceiptNo(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]): Code[20]
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        WarehouseReceiptLine.SetRange("Source Document", SourceDocument);
        WarehouseReceiptLine.SetRange("Source No.", SourceNo);
        if WarehouseReceiptLine.FindFirst() then;
        exit(WarehouseReceiptLine."No.");
    end;

    local procedure WhseShipFromSOWithNewBinCode(SalesHeader: Record "Sales Header")
    begin
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        Commit();
    end;

    local procedure FindWhseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; ActivityType: Enum "Warehouse Activity Type"; LocationCode: Code[10]; SourceNo: Code[20]; ActionType: Enum "Warehouse Action Type")
    begin
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.SetRange("Location Code", LocationCode);
        WarehouseActivityLine.SetRange("No.", FindWarehouseActivityNo(SourceNo, ActivityType));
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        if WarehouseActivityLine.FindSet() then;
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal; ShipmentDate: Date)
    begin
        // Random values used are not important for test.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', ItemNo, Quantity, LocationCode, ShipmentDate);
        Commit();
    end;

    local procedure GetGlobalNoSeriesCode(): Code[20]
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        NewCode: Code[20];
    begin
        // Init, get the global no series
        NewCode := CopyStr('GLOBAL' + Format(SessionId()), 1, 20);
        if not NoSeries.Get(NewCode) then begin
            NoSeries.Init();
            NoSeries.Validate(Code, NewCode);
            NoSeries.Validate("Default Nos.", true);
            NoSeries.Validate("Manual Nos.", true);
            NoSeries.Insert(true);
            CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, '', '');
            Commit();
        end;

        exit(NoSeries.Code)
    end;

    local procedure CreateNoSeriesLine(var NoSeriesLine: Record "No. Series Line"; SeriesCode: Code[20]; StartingNo: Code[20]; EndingNo: Code[20])
    var
        RecRef: RecordRef;
    begin
        NoSeriesLine.Init();
        NoSeriesLine.Validate("Series Code", SeriesCode);
        RecRef.GetTable(NoSeriesLine);
        NoSeriesLine.Validate("Line No.", 10000);

        if StartingNo = '' then
            NoSeriesLine.Validate("Starting No.", PadStr(InsStr(SeriesCode, '00000000', 3), 10))
        else
            NoSeriesLine.Validate("Starting No.", StartingNo);

        if EndingNo = '' then
            NoSeriesLine.Validate("Ending No.", PadStr(InsStr(SeriesCode, '99999999', 3), 10))
        else
            NoSeriesLine.Validate("Ending No.", EndingNo);
        NoSeriesLine.Validate(Implementation, NoSeriesLine.Implementation::Sequence);

        NoSeriesLine.Insert(true);
        Commit();
    end;

    local procedure ItemJournalSetup()
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type::Item, ItemJournalTemplate.Name);
        if ItemJournalBatch.Delete() then;
        ItemJournalBatch.Name := CopyStr(Format(SessionId()), 1, 10);
        ItemJournalBatch.Validate("No. Series", GetGlobalNoSeriesCode());
        ItemJournalBatch.Insert(true);
        Commit();
    end;

    local procedure CreateFullWarehouseSetup(var Location: Record Location)
    begin
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);  // Value used for number of bin per zone.
        Commit();
    end;

    local procedure CreateLocationSetup()
    begin
        CreateFullWarehouseSetup(LocationWhite);  // Location: White.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationWhite.Code, true);
        LibraryWarehouse.CreateLocationWMS(LocationGreen, false, true, true, true, true);  // Location: Green.
        LibraryWarehouse.CreateLocationWMS(LocationBlue, false, false, false, false, false);  // Location: Blue.
        LibraryWarehouse.CreateLocationWMS(LocationOrange, true, true, true, true, true);  // Location: Orange.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationOrange.Code, false);
        LibraryWarehouse.CreateLocationWMS(LocationOrange2, true, true, true, true, true);  // Location: Orange2.
        LibraryWarehouse.CreateLocationWMS(LocationOrange3, true, true, false, true, true);  // Location: Orange.
        LibraryWarehouse.CreateLocationWMS(LocationRed, false, false, false, true, true);  // Location: Red.
        LibraryWarehouse.CreateLocationWMS(LocationPink, true, false, true, true, true);  // Location: Orange.
        LibraryWarehouse.CreateInTransitLocation(LocationIntransit);

        LibraryWarehouse.CreateNumberOfBins(LocationOrange.Code, '', '', 3, false);  // 2 is required as minimun number of Bin must be 2.
        LibraryWarehouse.CreateNumberOfBins(LocationOrange2.Code, '', '', 3, false);
        LibraryWarehouse.CreateNumberOfBins(LocationOrange3.Code, '', '', 3, false);
        LibraryWarehouse.CreateNumberOfBins(LocationPink.Code, '', '', 3, false);
    end;

    local procedure Initialize()
    var
        WarehouseSetup: Record "Warehouse Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        if isInitialized then
            exit;
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        CreateLocationSetup();
        ItemJournalSetup();
        WarehouseSetup.Get();
        WarehouseSetup.Validate("Receipt Posting Policy", WarehouseSetup."Receipt Posting Policy"::"Posting errors are not processed");
        WarehouseSetup.Validate("Shipment Posting Policy", WarehouseSetup."Shipment Posting Policy"::"Posting errors are not processed");
        WarehouseSetup.Modify();
        isInitialized := true;
        Commit();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::DuplicateManagement, 'OnMakeContIndex', '', true, true)]
    local procedure OnMakeContIndex(var Contact: Record Contact; var IsHandled: Boolean)
    begin
        Ishandled := true;
    end;
}