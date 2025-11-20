codeunit 137049 "SCM Reservation"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Reservation] [SCM]
    end;

    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        OutputItemJournalTemplate: Record "Item Journal Template";
        OutputItemJournalBatch: Record "Item Journal Batch";
        GeneralLedgerSetup: Record "General Ledger Setup";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryPostInventoryToGL: Codeunit "Library - Post Inventory To GL";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryERM: Codeunit "Library - ERM";
        isInitialized: Boolean;
        MessageCounter: Integer;
        InitialInventory: Decimal;
        ExpCurrentReservedQty: Decimal;
        TotalQuantityErr: Label 'Total Quantity must match.';
        ReservedQuantityErr: Label 'Current Reserved Quantity must match.';
        CancelReservationTxt: Label 'Do you want to cancel all reservations';
        NegativeAdjQty: Decimal;
        OutputQuantity: Option Partial,Full,Excess;
        MissingTxt: Label '\\  * Some output is still missing.\  * Some consumption is still missing.\\ Do you still want to finish the order?';
        AmountsMustMatchErr: Label 'The amounts must match.';
        ApplyToItemEntryErr: Label 'Applies-to Entry must not be filled out when reservations exist in Item Ledger Entry';
        NotTrueDemandErr: Label 'You cannot reserve this entry because it is not a true demand or supply.';
        ReservEntryMustNotExistErr: Label 'Supply Reservation Entries for Item Ledger Entries must not exist after cancelling the reservation.';
        ProdOrderCreatedMsg: Label 'Released Prod. Order';
        ValueEntriesWerePostedTxt: Label 'value entries have been posted to the general ledger.';
        ShipDateChangedErr: Label 'Shipment Date should not be changed';
        ItemNo: Code[20];

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure PartialReserveSalesOrder()
    begin
        // Setup.
        Initialize();
        InitialInventory := LibraryRandom.RandDec(10, 2) + 100;  // Large random Inventory value.
        SalesOrderReservation(InitialInventory, InitialInventory - 1);  // Item inventory value and partial Sales quantity for reservation.
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure FullReserveSalesOrder()
    begin
        // Setup.
        Initialize();
        InitialInventory := LibraryRandom.RandDec(10, 2) + 100;  // Large random Inventory value.
        SalesOrderReservation(InitialInventory, InitialInventory);
    end;

    [Test]
    [HandlerFunctions('AutoReservationPageHandler')]
    [Scope('OnPrem')]
    procedure PartialAutoReserveSalesOrder()
    begin
        // Setup.
        Initialize();
        InitialInventory := LibraryRandom.RandDec(10, 2) + 100;  // Large random Inventory value.
        SalesOrderReservation(InitialInventory, InitialInventory - 1);  // Item inventory value and partial Sales quantity for reservation.
    end;

    [Test]
    [HandlerFunctions('AutoReservationPageHandler')]
    [Scope('OnPrem')]
    procedure FullAutoReserveSalesOrder()
    begin
        // Setup.
        Initialize();
        InitialInventory := LibraryRandom.RandDec(10, 2) + 100;  // Large random Inventory value.
        SalesOrderReservation(InitialInventory, InitialInventory);
    end;

    local procedure SalesOrderReservation(ItemQty: Decimal; SalesQty: Decimal)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
    begin
        // Create Item and Sales Order.
        CreateItemAndUpdateInventory(Item, ItemQty);
        CreateSalesOrder(SalesHeader, Item."No.", SalesQty);
        ExpCurrentReservedQty := SelectSalesLineQty(SalesHeader."No.");

        // Exercise: Sales Line -> Function -> Reserve.
        ReservationFromSalesOrder(SalesHeader."No.");

        // Verify: Verify Reservation Quantities through Page Handler.
        ReservationFromSalesOrder(SalesHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure ReduceReservedQtySalesOrder()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        ReservationEntry: Record "Reservation Entry";
        ReducedInventory: Decimal;
    begin
        // Setup.
        Initialize();
        InitialInventory := LibraryRandom.RandDec(10, 2) + 100;  // Large random Inventory value.
        CreateItemAndUpdateInventory(Item, InitialInventory);
        CreateSalesOrder(SalesHeader, Item."No.", InitialInventory);
        ReservationFromSalesOrder(SalesHeader."No.");

        // Exercise: Reduce reservation quantity in Reservation Entry.
        ReducedInventory := InitialInventory - 10;
        ReservationEntry.SetRange("Item No.", Item."No.");
        ReservationEntry.FindSet();
        repeat
            if ReservationEntry."Quantity (Base)" < 0 then
                ReducedInventory := -ReducedInventory;
            ReservationEntry.Validate("Quantity (Base)", ReservationEntry."Quantity (Base)" - ReducedInventory);
            ReservationEntry.Modify(true)
        until ReservationEntry.Next() = 0;

        // Verify: Verify Reservation Quantities through Page Handler.
        ExpCurrentReservedQty := SelectSalesLineQty(SalesHeader."No.") - ReducedInventory;
        ReservationFromSalesOrder(SalesHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure ReserveFromTwoPurchaseOrder()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        PurchaseQty: Decimal;
    begin
        // Setup: Create Item and Two Purchase Orders.
        Initialize();
        PurchaseQty := LibraryRandom.RandDec(10, 2);
        LibraryInventory.CreateItem(Item);
        CreateAndPostPurchaseOrder(PurchaseHeader, Item."No.", PurchaseQty, true);  // invoice.
        CreateAndPostPurchaseOrder(PurchaseHeader, Item."No.", PurchaseQty + 10, true);  // invoice.
        InitialInventory := PurchaseQty + PurchaseQty + 10;  // Quantity for Sales is sum of purchase.
        CreateSalesOrder(SalesHeader, Item."No.", InitialInventory);
        ExpCurrentReservedQty := SelectSalesLineQty(SalesHeader."No.");

        // Exercise: Sales Line -> Function -> Reserve.
        ReservationFromSalesOrder(SalesHeader."No.");

        // Verify: Verify Reservation Quantities through Page Handler.
        ReservationFromSalesOrder(SalesHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure PartialReservFirmPlanProdOrder()
    var
        ProductionOrder: Record "Production Order";
    begin
        // Setup.
        Initialize();
        InitialInventory := LibraryRandom.RandDec(10, 2) + 100;  // Large random Inventory value.
        ProdOrderReservation(ProductionOrder.Status::"Firm Planned", InitialInventory, InitialInventory - 1);  // Partial reservation.
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure FullReserveFirmPlanProdOrder()
    var
        ProductionOrder: Record "Production Order";
    begin
        // Setup.
        Initialize();
        InitialInventory := LibraryRandom.RandDec(10, 2) + 100;  // Large random Inventory value.
        ProdOrderReservation(ProductionOrder.Status::"Firm Planned", InitialInventory, InitialInventory);
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure PartialReserveRelProdOrder()
    var
        ProductionOrder: Record "Production Order";
    begin
        // Setup.
        Initialize();
        InitialInventory := LibraryRandom.RandDec(10, 2) + 100;  // Large random Inventory value.
        ProdOrderReservation(ProductionOrder.Status::Released, InitialInventory, InitialInventory - 1);  // Partial reservation.
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure FullReserveRelProdOrder()
    var
        ProductionOrder: Record "Production Order";
    begin
        // Setup.
        Initialize();
        InitialInventory := LibraryRandom.RandDec(10, 2) + 100;  // Large random Inventory value.
        ProdOrderReservation(ProductionOrder.Status::Released, InitialInventory, InitialInventory);
    end;

    [Test]
    [HandlerFunctions('AutoReservationPageHandler')]
    [Scope('OnPrem')]
    procedure PartialAutoReserveFirmPlanProd()
    var
        ProductionOrder: Record "Production Order";
    begin
        // Setup.
        Initialize();
        InitialInventory := LibraryRandom.RandDec(10, 2) + 100;  // Large random Inventory value.
        ProdOrderReservation(ProductionOrder.Status::"Firm Planned", InitialInventory, InitialInventory - 1);  // Partial reservation.
    end;

    [Test]
    [HandlerFunctions('AutoReservationPageHandler')]
    [Scope('OnPrem')]
    procedure FullAutoReseveFirmPlanProd()
    var
        ProductionOrder: Record "Production Order";
    begin
        // Setup.
        Initialize();
        InitialInventory := LibraryRandom.RandDec(10, 2) + 100;  // Large random Inventory value.
        ProdOrderReservation(ProductionOrder.Status::"Firm Planned", InitialInventory, InitialInventory);
    end;

    [Test]
    [HandlerFunctions('AutoReservationPageHandler')]
    [Scope('OnPrem')]
    procedure PartialAutoReserveRelProd()
    var
        ProductionOrder: Record "Production Order";
    begin
        // Setup.
        Initialize();
        InitialInventory := LibraryRandom.RandDec(10, 2) + 100;  // Large random Inventory value.
        ProdOrderReservation(ProductionOrder.Status::Released, InitialInventory, InitialInventory - 1);  // Partial reservation.
    end;

    [Test]
    [HandlerFunctions('AutoReservationPageHandler')]
    [Scope('OnPrem')]
    procedure FullAutoReserveRelProdOrder()
    var
        ProductionOrder: Record "Production Order";
    begin
        // Setup.
        Initialize();
        InitialInventory := LibraryRandom.RandDec(10, 2) + 100;  // Large random Inventory value.
        ProdOrderReservation(ProductionOrder.Status::Released, InitialInventory, InitialInventory);
    end;

    local procedure ProdOrderReservation(ProdOrderStatus: Enum "Production Order Status"; ItemQty: Decimal; SalesQty: Decimal)
    var
        ProductionOrder: Record "Production Order";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
    begin
        // Create Item and Create Production Order. Create Sales Order and Reserve.
        CreateItemsSetup(Item);
        CreateAndRefreshProdOrder(ProductionOrder, ProdOrderStatus, Item."No.", ItemQty);
        CreateSalesOrder(SalesHeader, Item."No.", SalesQty);
        ExpCurrentReservedQty := SelectSalesLineQty(SalesHeader."No.");

        // Exercise: Sales Line -> Function -> Reserve.
        ReservationFromSalesOrder(SalesHeader."No.");

        // Verify: Verify Reservation Quantities through Page Handler.
        ReservationFromSalesOrder(SalesHeader."No.");
    end;

    [Test]
    [HandlerFunctions('TwoProdOrderReservPageHandler')]
    [Scope('OnPrem')]
    procedure FullReservFirmRelProdOrder()
    begin
        // Setup.
        Initialize();
        InitialInventory := LibraryRandom.RandDec(10, 2) + 100;
        ReservFirmAndReleasedProdOrder(InitialInventory - 1, 1, InitialInventory);  // Prod. Qty.: Firm Planned,Released and Sales Line Qty.
    end;

    [Test]
    [HandlerFunctions('TwoProdAutoReservPageHandler')]
    [Scope('OnPrem')]
    procedure FullAutoReservFirmRelProdOrder()
    begin
        // Setup.
        Initialize();
        InitialInventory := LibraryRandom.RandDec(10, 2) + 100;
        ReservFirmAndReleasedProdOrder(InitialInventory - 1, 1, InitialInventory);  // Prod. Qty.: Firm Planned,Released and Sales Line Qty.
    end;

    [Test]
    [HandlerFunctions('TwoProdOrderReservPageHandler')]
    [Scope('OnPrem')]
    procedure PartialReservFirmRelProdOrder()
    begin
        // Setup.
        Initialize();
        InitialInventory := LibraryRandom.RandDec(10, 2) + 100;
        ReservFirmAndReleasedProdOrder(
          InitialInventory / 2, InitialInventory / 2,
          InitialInventory - LibraryRandom.RandDec(10, 2));  // Prod. Qty.: Firm Planned,Released and Sales Line Qty.
    end;

    [Test]
    [HandlerFunctions('TwoProdAutoReservPageHandler')]
    [Scope('OnPrem')]
    procedure PartAutoReservFirmRelProdOrder()
    begin
        // Setup.
        Initialize();
        InitialInventory := LibraryRandom.RandDec(10, 2) + 100;
        ReservFirmAndReleasedProdOrder(
          InitialInventory / 2, InitialInventory / 2,
          InitialInventory - LibraryRandom.RandDec(10, 2));  // Prod. Qty.: Firm Planned,Released and Sales Line Qty.
    end;

    local procedure ReservFirmAndReleasedProdOrder(FirmPlannedProdOrderQty: Decimal; ReleasedProdOrderQty: Decimal; SalesQty: Decimal)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        ProductionOrder: Record "Production Order";
    begin
        // Create Item, Firm Planned and Released Production Order. Create Sales Order and Reserve.
        CreateItemsSetup(Item);
        CreateAndRefreshProdOrder(ProductionOrder, ProductionOrder.Status::"Firm Planned", Item."No.", FirmPlannedProdOrderQty);
        CreateAndRefreshProdOrder(ProductionOrder, ProductionOrder.Status::Released, Item."No.", ReleasedProdOrderQty);
        CreateSalesOrder(SalesHeader, Item."No.", SalesQty);
        ExpCurrentReservedQty := SelectSalesLineQty(SalesHeader."No.");

        // Exercise: Sales Line -> Function -> Reserve.
        ReservationFromSalesOrder(SalesHeader."No.");

        // Verify: Verify Reservation Quantities through Page Handler.
        ReservationFromSalesOrder(SalesHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure DeleteReleasedProdOrderReserv()
    var
        ProductionOrder: Record "Production Order";
    begin
        // Setup.
        Initialize();
        DeleteProductionOrderReserve(ProductionOrder.Status::Released);
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure DeleteFirmPlanProdOrderReserv()
    var
        ProductionOrder: Record "Production Order";
    begin
        // Setup.
        Initialize();
        DeleteProductionOrderReserve(ProductionOrder.Status::"Firm Planned");
    end;

    [Test]
    [HandlerFunctions('AutoReservationPageHandler')]
    [Scope('OnPrem')]
    procedure DeleteRelProdOrderAutoReserv()
    var
        ProductionOrder: Record "Production Order";
    begin
        // Setup.
        Initialize();
        DeleteProductionOrderReserve(ProductionOrder.Status::Released);
    end;

    [Test]
    [HandlerFunctions('AutoReservationPageHandler')]
    [Scope('OnPrem')]
    procedure DeleteFirmPlanProdAutoReserv()
    var
        ProductionOrder: Record "Production Order";
    begin
        // Setup.
        Initialize();
        DeleteProductionOrderReserve(ProductionOrder.Status::"Firm Planned");
    end;

    local procedure DeleteProductionOrderReserve(Status: Enum "Production Order Status")
    var
        ProductionOrder: Record "Production Order";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
    begin
        // Create Item, Released Production Order or Firm Planned Production Order. Create Sales Order and Reserve.
        CreateItemsSetup(Item);
        InitialInventory := LibraryRandom.RandDec(10, 2) + 100;
        CreateAndRefreshProdOrder(ProductionOrder, Status, Item."No.", InitialInventory);
        CreateSalesOrder(SalesHeader, Item."No.", InitialInventory);
        ExpCurrentReservedQty := SelectSalesLineQty(SalesHeader."No.");

        // Sales Line -> Function -> Reserve.
        ReservationFromSalesOrder(SalesHeader."No.");

        // Exercise: Delete Production Order.
        DeleteProductionOrder(Status, Item."No.");

        // Verify: Verify there is no reserved quantity on Sales Line after deletion of Production Order.
        VerifyZeroReservationSalesQty(SalesHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ReservationCancelPageHandler,CancelReserveConfirmHandler')]
    [Scope('OnPrem')]
    procedure CancelPartialResvFirmPlanProd()
    var
        ProductionOrder: Record "Production Order";
    begin
        // Setup.
        Initialize();
        InitialInventory := LibraryRandom.RandDec(10, 2) + 100;  // Large random Inventory value.
        ProdOrderReservationCancel(ProductionOrder.Status::"Firm Planned", InitialInventory, InitialInventory - 1);  // Partial reservation.
    end;

    [Test]
    [HandlerFunctions('ReservationCancelPageHandler,CancelReserveConfirmHandler')]
    [Scope('OnPrem')]
    procedure CancelFullResvFirmPlanProd()
    var
        ProductionOrder: Record "Production Order";
    begin
        // Setup.
        Initialize();
        InitialInventory := LibraryRandom.RandDec(10, 2) + 100;  // Large random Inventory value.
        ProdOrderReservationCancel(ProductionOrder.Status::"Firm Planned", InitialInventory, InitialInventory);
    end;

    [Test]
    [HandlerFunctions('ReservationCancelPageHandler,CancelReserveConfirmHandler')]
    [Scope('OnPrem')]
    procedure CancelPartialResvRelProdOrder()
    var
        ProductionOrder: Record "Production Order";
    begin
        // Setup.
        Initialize();
        InitialInventory := LibraryRandom.RandDec(10, 2) + 100;  // Large random Inventory value.
        ProdOrderReservationCancel(ProductionOrder.Status::Released, InitialInventory, InitialInventory - 1);  // Partial reservation.
    end;

    [Test]
    [HandlerFunctions('ReservationCancelPageHandler,CancelReserveConfirmHandler')]
    [Scope('OnPrem')]
    procedure CancelFullReserveRelProdOrder()
    var
        ProductionOrder: Record "Production Order";
    begin
        // Setup.
        Initialize();
        InitialInventory := LibraryRandom.RandDec(10, 2) + 100;  // Large random Inventory value.
        ProdOrderReservationCancel(ProductionOrder.Status::Released, InitialInventory, InitialInventory);
    end;

    local procedure ProdOrderReservationCancel(ProdOrderStatus: Enum "Production Order Status"; ItemQty: Decimal; SalesQty: Decimal)
    var
        ProductionOrder: Record "Production Order";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
    begin
        // Create Item and Create Production Order. Create Sales Order and Reserve.
        CreateItemsSetup(Item);
        CreateAndRefreshProdOrder(ProductionOrder, ProdOrderStatus, Item."No.", ItemQty);
        CreateSalesOrder(SalesHeader, Item."No.", SalesQty);

        // Sales Line -> Function -> Reserve.
        ReservationFromSalesOrder(SalesHeader."No.");

        // Exercise: Sales Line -> Function -> Cancel Reservation from Current Line.
        ReservationFromSalesOrder(SalesHeader."No.");

        // Verify: Verify there is no reserved quantity on Sales Line after cancellation of reservation.
        VerifyZeroReservationSalesQty(SalesHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ReservationCancelPageHandler,CancelReserveConfirmHandler')]
    [Scope('OnPrem')]
    procedure CancelPartialReserveSalesOrder()
    begin
        // Setup.
        Initialize();
        InitialInventory := LibraryRandom.RandDec(10, 2) + 100;  // Large random Inventory value.
        SalesOrderReservationCancel(
          InitialInventory, InitialInventory - 1);  // Item inventory value and partial Sales quantity for reservation.
    end;

    [Test]
    [HandlerFunctions('ReservationCancelPageHandler,CancelReserveConfirmHandler')]
    [Scope('OnPrem')]
    procedure CancelFullReserveSalesOrder()
    begin
        // Setup.
        Initialize();
        InitialInventory := LibraryRandom.RandDec(10, 2) + 100;  // Large random Inventory value.
        SalesOrderReservationCancel(InitialInventory, InitialInventory);
    end;

    [Test]
    [HandlerFunctions('AutoReserveCancelPageHandler,CancelReserveConfirmHandler')]
    [Scope('OnPrem')]
    procedure CancelPartialAutoReserveSales()
    begin
        // Setup.
        Initialize();
        InitialInventory := LibraryRandom.RandDec(10, 2) + 100;  // Large random Inventory value.
        SalesOrderReservationCancel(
          InitialInventory, InitialInventory - 1);  // Item inventory value and partial Sales quantity for reservation.
    end;

    [Test]
    [HandlerFunctions('AutoReserveCancelPageHandler,CancelReserveConfirmHandler')]
    [Scope('OnPrem')]
    procedure CancelFullAutoReserveSales()
    begin
        // Setup.
        Initialize();
        InitialInventory := LibraryRandom.RandDec(10, 2) + 100;  // Large random Inventory value.
        SalesOrderReservationCancel(InitialInventory, InitialInventory);
    end;

    local procedure SalesOrderReservationCancel(ItemQty: Decimal; SalesQty: Decimal)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
    begin
        // Create Item and Sales Order.
        CreateItemAndUpdateInventory(Item, ItemQty);
        CreateSalesOrder(SalesHeader, Item."No.", SalesQty);

        // Sales Line -> Function -> Reserve.
        ReservationFromSalesOrder(SalesHeader."No.");

        // Exercise: Sales Line -> Function -> Cancel Reservation from Current Line.
        ReservationFromSalesOrder(SalesHeader."No.");

        // Verify: Verify there is no reserved quantity on Sales Line after cancellation of reservation.
        VerifyZeroReservationSalesQty(SalesHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure FullReserveFromPurchaseOrder()
    begin
        // Setup.
        Initialize();
        InitialInventory := LibraryRandom.RandDec(10, 2) + 100;  // Large random Purchase quantity.
        ReserveFromPurchaseOrder(InitialInventory, InitialInventory, true);  // Purchase Invoice - True.
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure PartialReserveFromPurchOrder()
    begin
        // Setup.
        Initialize();
        InitialInventory := LibraryRandom.RandDec(10, 2) + 100;  // Large random Purchase quantity.
        ReserveFromPurchaseOrder(InitialInventory, InitialInventory - 1, true);
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure FullResvPurchaseOrderReceive()
    begin
        // Setup.
        Initialize();
        InitialInventory := LibraryRandom.RandDec(10, 2) + 100;  // Large random Purchase quantity.
        ReserveFromPurchaseOrder(InitialInventory, InitialInventory, false);  // Purchase Invoice - False.
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure PartialResvPurchOrderReceive()
    begin
        // Setup.
        Initialize();
        InitialInventory := LibraryRandom.RandDec(10, 2) + 100;  // Large random Purchase quantity.
        ReserveFromPurchaseOrder(InitialInventory, InitialInventory - 1, false);
    end;

    local procedure ReserveFromPurchaseOrder(ItemQty: Decimal; SalesQty: Decimal; Invoice: Boolean)
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
    begin
        // Create Item and Purchase Orders.
        LibraryInventory.CreateItem(Item);
        CreateAndPostPurchaseOrder(PurchaseHeader, Item."No.", ItemQty, Invoice);
        CreateSalesOrder(SalesHeader, Item."No.", SalesQty);
        ExpCurrentReservedQty := SelectSalesLineQty(SalesHeader."No.");

        // Exercise: Sales Line -> Function -> Reserve.
        ReservationFromSalesOrder(SalesHeader."No.");

        // Verify: Verify Reservation Quantities through Page Handler.
        ReservationFromSalesOrder(SalesHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure ResvFromPurchPartialQtyReceive()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        PurchaseQty: Decimal;
    begin
        // Setup: Create Item and Purchase Orders with Partial Qty to Receive.
        Initialize();
        PurchaseQty := LibraryRandom.RandDec(10, 2) + 100;  // Large random Purchase quantity.
        LibraryInventory.CreateItem(Item);
        CreatePurchaseOrder(PurchaseHeader, Item."No.", PurchaseQty);

        // Update Purchase Order - Qty to Receive less then Quantity.
        InitialInventory := PurchaseQty - 1;
        UpdatePurchLineQtyToReceive(PurchaseHeader."No.", InitialInventory);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);  // Receive only.
        CreateSalesOrder(SalesHeader, Item."No.", InitialInventory);
        ExpCurrentReservedQty := SelectSalesLineQty(SalesHeader."No.");

        // Exercise: Sales Line -> Function -> Reserve.
        ReservationFromSalesOrder(SalesHeader."No.");

        // Verify: Verify Reservation Quantities through Page Handler.
        ReservationFromSalesOrder(SalesHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,SendAvailabilityNotificationHandler,NotificationDetailsHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure NegativeAdjAfterReservation()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        ItemJournalLine: Record "Item Journal Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        ItemCheckAvail: Codeunit "Item-Check Avail.";
    begin
        // Setup: Update Sales Setup for Stockout warning. Create Item with Inventory and Reserve full qty in Sales Order.
        Initialize();
        SalesReceivablesSetup.Get();
        UpdateSalesReceivablesSetup(true);  // Stockout Warning - TRUE
        LibraryERM.SetEnableDataCheck(false);
        InitialInventory := LibraryRandom.RandDec(10, 2) + 100;  // Large random Inventory value.

        CreateItemAndUpdateInventory(Item, InitialInventory);
        CreateSalesOrder(SalesHeader, Item."No.", InitialInventory);

        ItemNo := Item."No.";
        // Sales Line -> Function -> Reserve, and Create Item Journal Line with Negative adjustment for the item.
        ReservationFromSalesOrder(SalesHeader."No.");
        NegativeAdjQty := LibraryRandom.RandDec(10, 2);
        CreateItemJournalLine(
          ItemJournalLine, Item."No.", NegativeAdjQty, ItemJournalLine."Entry Type"::"Negative Adjmt.");

        // Exercise and Verify: Check Stockout on Item Journal Line and verify Check Availability page opens.
        // Verify Negative Adjustment quantity in Check Availability page handler.
        ItemCheckAvail.ItemJnlCheckLine(ItemJournalLine);

        // Teardown.
        UpdateSalesReceivablesSetup(SalesReceivablesSetup."Stockout Warning");
        NotificationLifecycleMgt.RecallAllNotifications();
        LibraryERM.SetEnableDataCheck(true);
    end;

    [Test]
    [HandlerFunctions('ReservationOutputPartialPageHandler')]
    [Scope('OnPrem')]
    procedure PartialOutputReleasedProdReserve()
    begin
        // Setup.
        Initialize();
        PostOutputForProduction(OutputQuantity::Partial);  // Post Partial Output.
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure FullOutputReleasedProdReserve()
    begin
        // Setup.
        Initialize();
        PostOutputForProduction(OutputQuantity::Full);  // Post Full Output.
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure ExcessOutputReleasedProdReserve()
    begin
        // Setup.
        Initialize();
        PostOutputForProduction(OutputQuantity::Excess);  // Post Excess Output.
    end;

    [Test]
    [HandlerFunctions('TwoProdAutoReservPageHandler')]
    [Scope('OnPrem')]
    procedure PartialOutputReleasedProdAutoReserve()
    begin
        // Setup.
        Initialize();
        PostOutputForProduction(OutputQuantity::Partial);  // Post Partial Output with Auto Reserve.
    end;

    [Test]
    [HandlerFunctions('AutoReservationPageHandler')]
    [Scope('OnPrem')]
    procedure FullOutputReleasedProdAutoReserve()
    begin
        // Setup.
        Initialize();
        PostOutputForProduction(OutputQuantity::Full);  // Post Full Output with Auto Reserve.
    end;

    [Test]
    [HandlerFunctions('AutoReservationPageHandler')]
    [Scope('OnPrem')]
    procedure ExcessOutputReleasedProdAutoReserve()
    begin
        // Setup.
        Initialize();
        PostOutputForProduction(OutputQuantity::Excess);  // Post Excess Output with Auto Reserve.
    end;

    local procedure PostOutputForProduction(OutputValue: Option Partial,Full,Excess)
    var
        ProductionOrder: Record "Production Order";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        ItemJournalLine: Record "Item Journal Line";
        FinishedQty: Decimal;
    begin
        // Create Item and Create Production Order.
        CreateItemsSetup(Item);
        InitialInventory := LibraryRandom.RandInt(5) + 5;  // Random Qty.
        CreateAndRefreshProdOrder(ProductionOrder, ProductionOrder.Status::Released, Item."No.", InitialInventory);
        ExpCurrentReservedQty := InitialInventory;

        // Create Sales Order and against Released Prod. Order line.
        CreateSalesOrder(SalesHeader, Item."No.", ExpCurrentReservedQty);
        ReservationFromSalesOrder(SalesHeader."No.");

        // Create Output Journal with required Output Quantity.
        CreateOutputJournal(ProductionOrder."No.");
        case OutputValue of
            OutputValue::Partial:
                begin
                    SelectOutputJournalLine(ItemJournalLine, ProductionOrder."No.");
                    FinishedQty := ItemJournalLine."Output Quantity" - 1;  // Reduced Output Qty.
                    UpdateOutputJournal(ItemJournalLine, FinishedQty);
                end;
            OutputValue::Full:
                FinishedQty := InitialInventory;
            OutputValue::Excess:
                begin
                    SelectOutputJournalLine(ItemJournalLine, ProductionOrder."No.");
                    FinishedQty := ItemJournalLine."Output Quantity" + 1;  // Increase Output Qty.
                    InitialInventory := FinishedQty;
                    UpdateOutputJournal(ItemJournalLine, FinishedQty);
                end;
        end;

        // Exercise: Post Output Journal.
        LibraryInventory.PostItemJournalLine(OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);

        // Verify : Verify Reservation values through Handler.
        ReservationFromSalesOrder(SalesHeader."No.");

        // Verify Quantity on Item Ledger Entry.
        VerifyQtyOnItemLedgerEntry(Item."No.", FinishedQty);
    end;

    [Test]
    [HandlerFunctions('ReservationFinishProductionPageHandler,MissingOutputConfirmHandler')]
    [Scope('OnPrem')]
    procedure FinishReleasedProdReserve()
    var
        ProductionOrder: Record "Production Order";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        ItemJournalLine: Record "Item Journal Line";
        FinishedQty: Decimal;
    begin
        // [FEATURE] [Reservation] [Production]
        // [SCENARIO] Verify reserved Qty. = (R - 1) after creating released prod. order with Qty. = R, creating sales order with reserverd Qty. = R, posting output with Qty. = (R - 1), finishing production order.

        // [GIVEN] Released Production Order with quantity = R. Sales Order reserved R quantity.
        Initialize();
        CreateItemsSetup(Item);
        InitialInventory := LibraryRandom.RandInt(5) + 1;
        CreateAndRefreshProdOrder(ProductionOrder, ProductionOrder.Status::Released, Item."No.", InitialInventory);
        ExpCurrentReservedQty := InitialInventory;
        CreateSalesOrder(SalesHeader, Item."No.", ExpCurrentReservedQty);
        ReservationFromSalesOrder(SalesHeader."No.");

        // [GIVEN] Post Output Journal with Output Quantity = R - 1.
        CreateOutputJournal(ProductionOrder."No.");
        SelectOutputJournalLine(ItemJournalLine, ProductionOrder."No.");
        FinishedQty := ItemJournalLine."Output Quantity" - 1;  // Reduced Output Qty.
        ExpCurrentReservedQty := FinishedQty;
        UpdateOutputJournal(ItemJournalLine, FinishedQty);
        LibraryInventory.PostItemJournalLine(OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);

        // [WHEN] Finish Production Order.
        LibraryVariableStorage.Enqueue(MissingTxt);
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // [THEN] Verify Reserved = R - 1, Qty to Reserve = R.
        ReservationFromSalesOrder(SalesHeader."No.");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure PartialShipAfterReserve()
    begin
        // Setup.
        Initialize();
        InitialInventory := LibraryRandom.RandDec(10, 2) + 10;
        ShipmentAfterReserve(InitialInventory, InitialInventory - LibraryRandom.RandDec(10, 2));  // Shipment Quantity - Partial.
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure FullShipAfterReserve()
    begin
        // Setup.
        Initialize();
        InitialInventory := LibraryRandom.RandDec(10, 2);
        ShipmentAfterReserve(InitialInventory, InitialInventory);  // Shipment Quantity - Full.
    end;

    [Test]
    [HandlerFunctions('AutoReservationPageHandler')]
    [Scope('OnPrem')]
    procedure PartialShipAfterAutoReserve()
    begin
        // Setup.
        Initialize();
        InitialInventory := LibraryRandom.RandDec(10, 2) + 10;
        ShipmentAfterReserve(InitialInventory, InitialInventory - LibraryRandom.RandDec(10, 2));  // Shipment Quantity - Partial with Auto reserve.
    end;

    [Test]
    [HandlerFunctions('AutoReservationPageHandler')]
    [Scope('OnPrem')]
    procedure FullShipAfterAutoReserve()
    begin
        // Setup.
        Initialize();
        InitialInventory := LibraryRandom.RandDec(10, 2);
        ShipmentAfterReserve(InitialInventory, InitialInventory);  // Shipment Quantity - Full with Auto reserve.
    end;

    local procedure ShipmentAfterReserve(PurchaseQty: Decimal; QtyToShip: Decimal)
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Create Item and Purchase Orders.
        LibraryInventory.CreateItem(Item);
        CreateAndPostPurchaseOrder(PurchaseHeader, Item."No.", PurchaseQty, true);
        CreateSalesOrder(SalesHeader, Item."No.", PurchaseQty);

        // For full quantity on Sales Line: Function -> Reserve; and Update Quantity to Ship.
        ReservationFromSalesOrder(SalesHeader."No.");
        SelectSalesLine(SalesLine, SalesHeader."No.");
        SalesLine.Validate("Qty. to Ship", QtyToShip);
        SalesLine.Modify(true);

        // Exercise: Ship Sales Order.
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // Verify: Verify Sales Shipment Lines.
        VerifySalesShipment(SalesHeader."No.", QtyToShip);
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure ReserveProdOrderComponentForFirmPlanned()
    var
        ProductionOrder: Record "Production Order";
    begin
        // Setup.
        Initialize();
        ProductionOrderComponentReservation(ProductionOrder.Status::"Firm Planned");
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure ReserveProdOrderComponentForReleased()
    var
        ProductionOrder: Record "Production Order";
    begin
        // Setup.
        Initialize();
        ProductionOrderComponentReservation(ProductionOrder.Status::Released);
    end;

    [Test]
    [HandlerFunctions('AutoReservationPageHandler')]
    [Scope('OnPrem')]
    procedure AutoReserveProdOrderComponentFirmPlanned()
    var
        ProductionOrder: Record "Production Order";
    begin
        // Setup.
        Initialize();
        ProductionOrderComponentReservation(ProductionOrder.Status::"Firm Planned");  // Prod. Order Component reservation with Auto Reserve.
    end;

    [Test]
    [HandlerFunctions('AutoReservationPageHandler')]
    [Scope('OnPrem')]
    procedure AutoReserveProdOrderComponentReleased()
    var
        ProductionOrder: Record "Production Order";
    begin
        // Setup.
        Initialize();
        ProductionOrderComponentReservation(ProductionOrder.Status::Released);  // Prod. Order Component reservation with Auto Reserve.
    end;

    local procedure ProductionOrderComponentReservation(ProdOrderStatus: Enum "Production Order Status")
    var
        ProductionOrder: Record "Production Order";
        ParentItem: Record Item;
        ChildItemNo: Code[20];
    begin
        ChildItemNo := CreateItemsSetup(ParentItem);
        InitialInventory := SelectItemInventory(ChildItemNo);
        ExpCurrentReservedQty := LibraryRandom.RandInt(5);
        CreateAndRefreshProdOrder(ProductionOrder, ProdOrderStatus, ParentItem."No.", ExpCurrentReservedQty);

        // Exercise: Production Order Component -> Functions -> Reserve.
        ReservationFromProductionOrderComponents(ChildItemNo);

        // Verify: Verify Reservation values through Handler.
        ReservationFromProductionOrderComponents(ChildItemNo);
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure PartialReserveSalesAdjustCostAndPostToGL()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Post Inventory Cost To GL] [Sales] [Reservation]
        // [SCENARIO] Verify that Total Amount in GL Entries is correct after reserving Sales Order partially and run "Adjust Cost" - "Post to GL".

        // [GIVEN] Sales Order with partial reservation.
        // [WHEN] Run Adjust Cost and Post Inventory Cost to G/L.
        // [THEN] Total amount in G/L for Inventory Account is correct.
        Initialize();
        InitialInventory := LibraryRandom.RandDec(10, 2) + 100;  // Large random Inventory value.
        SalesOrderReservationAndPostToGL(InitialInventory, InitialInventory - 1);  // Item inventory value and partial Sales quantity for reservation.
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure FullReserveSalesAdjustCostAndPostToGL()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Post Inventory Cost To GL] [Sales] [Reservation]
        // [SCENARIO] Verify that Total Amount in GL Entries is correct after reserving Sales Order and run "Adjust Cost" - "Post to GL".

        // [GIVEN] Sales Order with full reservation.
        // [WHEN] Run Adjust Cost and Post Inventory Cost to G/L.
        // [THEN] Total amount in G/L for Inventory Account is correct.
        Initialize();
        InitialInventory := LibraryRandom.RandDec(10, 2) + 100;  // Large random Inventory value.
        SalesOrderReservationAndPostToGL(InitialInventory, InitialInventory);
    end;

    local procedure SalesOrderReservationAndPostToGL(ItemQty: Decimal; SalesQty: Decimal)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
    begin
        // Create Item and Sales Order.
        CreateItemAndUpdateInventory(Item, ItemQty);
        CreateSalesOrder(SalesHeader, Item."No.", SalesQty);

        // Sales Line -> Function -> Reserve.
        ReservationFromSalesOrder(SalesHeader."No.");

        // Exercise: Run Adjust Cost and Post Inventory Cost to G/L.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

        // Verify: Verify Total amount in G/L for Inventory Account.
        VerifyGLEntry(Item."No.");
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure PartialReserveRelProdOrderAdjustCostAndPostToGL()
    var
        ProductionOrder: Record "Production Order";
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Post Inventory Cost To GL] [Production] [Reservation]
        // [SCENARIO] Verify that Total Amount in GL Entries is correct after creating Production Order, Sales Order reserved partially and run "Adjust Cost" - "Post to GL".

        // [GIVEN] Sales Order with partial reservation.
        // [WHEN] Run Adjust Cost and Post Inventory Cost to G/L.
        // [THEN] Total amount in G/L for Inventory Account is correct.
        Initialize();
        InitialInventory := LibraryRandom.RandDec(10, 2) + 100;  // Large random Inventory value.
        ProdOrderReservationAndPostToGL(ProductionOrder.Status::Released, InitialInventory, InitialInventory - 1);  // Partial reservation.
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure FullReserveRelProdOrderAdjustCostAndPostToGL()
    var
        ProductionOrder: Record "Production Order";
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Post Inventory Cost To GL] [Production] [Reservation]
        // [SCENARIO] Verify that Total Amount in GL Entries is correct after creating Production Order, Sales Order reserved and run "Adjust Cost" - "Post to GL".

        // [GIVEN] Released production Order with full reservation.
        // [WHEN] Run Adjust Cost and Post Inventory Cost to G/L.
        // [THEN] Total amount in G/L for Inventory Account is correct.
        Initialize();
        InitialInventory := LibraryRandom.RandDec(10, 2) + 100;  // Large random Inventory value.
        ProdOrderReservationAndPostToGL(ProductionOrder.Status::Released, InitialInventory, InitialInventory);
    end;

    local procedure ProdOrderReservationAndPostToGL(ProdOrderStatus: Enum "Production Order Status"; ItemQty: Decimal; SalesQty: Decimal)
    var
        ProductionOrder: Record "Production Order";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        ChildItemNo: Code[20];
    begin
        // Create Item and Create Production Order. Create Sales Order and Reserve.
        ChildItemNo := CreateItemsSetup(Item);
        CreateAndRefreshProdOrder(ProductionOrder, ProdOrderStatus, Item."No.", ItemQty);
        CreateSalesOrder(SalesHeader, Item."No.", SalesQty);

        // Sales Line -> Function -> Reserve.
        ReservationFromSalesOrder(SalesHeader."No.");

        // Exercise: Run Adjust Cost and Post Inventory Cost to G/L.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

        // Verify: Verify amount for component in G/L for Inventory Account.
        VerifyGLEntry(ChildItemNo);
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure PartialReserveSalesWithApplyToItemEntryError()
    begin
        // Setup.
        Initialize();
        InitialInventory := LibraryRandom.RandDec(10, 2) + 100;  // Large random Inventory value.
        SalesOrderReservationAndApplyToItemEntryAndPost(InitialInventory, InitialInventory - 1);  // Item inventory, partial Sales quantity with Apply To Item Entry.
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure FullReserveSalesWithApplyToItemEntryError()
    begin
        // Setup.
        Initialize();
        InitialInventory := LibraryRandom.RandDec(10, 2) + 100;  // Large random Inventory value.
        SalesOrderReservationAndApplyToItemEntryAndPost(InitialInventory, InitialInventory);
    end;

    local procedure SalesOrderReservationAndApplyToItemEntryAndPost(ItemQty: Decimal; SalesQty: Decimal)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // Create Item and Sales Order.
        CreateItemAndUpdateInventory(Item, ItemQty);
        CreateSalesOrder(SalesHeader, Item."No.", SalesQty);

        // Update Sales Line with Apply to Item Entry.
        SelectItemLedgerEntry(ItemLedgerEntry, Item."No.");
        UpdateSalesLineApplyToEntry(SalesHeader."No.", ItemLedgerEntry."Entry No.");

        // Sales Line -> Function -> Reserve.
        ReservationFromSalesOrder(SalesHeader."No.");

        // Exercise: Post Sales Order as Ship.
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // Verify: Verify error message - Applies-to Entry must not be filled out when reservations exist.
        Assert.ExpectedError(ApplyToItemEntryErr);
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure PartialReserveSalesAndShipWithoutApplyToItemEntry()
    begin
        // Setup.
        Initialize();
        InitialInventory := LibraryRandom.RandDec(10, 2) + 100;  // Large random Inventory value.
        SalesOrderReservationAndShipWithoutApplyToItemEntry(InitialInventory, InitialInventory - 1);  // Item inventory, partial Sales quantity without Apply To Item Entry.
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure FullReserveSalesAndShipWithoutApplyToItemEntry()
    begin
        // Setup.
        Initialize();
        InitialInventory := LibraryRandom.RandDec(10, 2) + 100;  // Large random Inventory value.
        SalesOrderReservationAndShipWithoutApplyToItemEntry(InitialInventory, InitialInventory);
    end;

    local procedure SalesOrderReservationAndShipWithoutApplyToItemEntry(ItemQty: Decimal; SalesQty: Decimal)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // Create Item and Sales Order.
        CreateItemAndUpdateInventory(Item, ItemQty);
        CreateSalesOrder(SalesHeader, Item."No.", SalesQty);

        // Update Sales Line with Apply to Item Entry.
        SelectItemLedgerEntry(ItemLedgerEntry, Item."No.");
        UpdateSalesLineApplyToEntry(SalesHeader."No.", ItemLedgerEntry."Entry No.");

        // Sales Line -> Function -> Reserve.
        ReservationFromSalesOrder(SalesHeader."No.");

        // Update Sales Line with Apply to Item Entry equals Zero.
        UpdateSalesLineApplyToEntry(SalesHeader."No.", 0);  // Value Zero important.

        // Exercise: Post Sales Order as Ship.
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // Verify: Verify Sales Shipment posted successfully.
        VerifySalesShipment(SalesHeader."No.", SalesQty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingIssuesSaleILE()
    begin
        RoundingIssuesRunScenario(DATABASE::"Item Ledger Entry", DATABASE::"Sales Line");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingIssuesSalePurchase()
    begin
        RoundingIssuesRunScenario(DATABASE::"Purchase Line", DATABASE::"Sales Line");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingIssuesSaleProduction()
    begin
        RoundingIssuesRunScenario(DATABASE::"Prod. Order Line", DATABASE::"Sales Line");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingIssuesSaleAssembly()
    begin
        RoundingIssuesRunScenario(DATABASE::"Assembly Header", DATABASE::"Sales Line");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingIssuesSaleTransfer()
    begin
        RoundingIssuesRunScenario(DATABASE::"Transfer Line", DATABASE::"Sales Line");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingIssuesSaleSale()
    begin
        RoundingIssuesRunScenario(DATABASE::"Sales Line", DATABASE::"Sales Line");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingIssuesPurchaseILE()
    begin
        RoundingIssuesRunScenario(DATABASE::"Item Ledger Entry", DATABASE::"Purchase Line");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingIssuesPurchasePurchase()
    begin
        RoundingIssuesRunScenario(DATABASE::"Purchase Line", DATABASE::"Purchase Line");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingIssuesPurchaseProduction()
    begin
        RoundingIssuesRunScenario(DATABASE::"Prod. Order Line", DATABASE::"Purchase Line");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingIssuesPurchaseAssembly()
    begin
        RoundingIssuesRunScenario(DATABASE::"Assembly Header", DATABASE::"Purchase Line");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingIssuesPurchaseTransfer()
    begin
        RoundingIssuesRunScenario(DATABASE::"Transfer Line", DATABASE::"Purchase Line");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingIssuesPurchaseSale()
    begin
        RoundingIssuesRunScenario(DATABASE::"Sales Line", DATABASE::"Purchase Line");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingIssuesTransferILE()
    begin
        RoundingIssuesRunScenario(DATABASE::"Item Ledger Entry", DATABASE::"Transfer Line");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingIssuesTransferPurchase()
    begin
        RoundingIssuesRunScenario(DATABASE::"Purchase Line", DATABASE::"Transfer Line");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingIssuesTransferProduction()
    begin
        RoundingIssuesRunScenario(DATABASE::"Prod. Order Line", DATABASE::"Transfer Line");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingIssuesTransferAssembly()
    begin
        RoundingIssuesRunScenario(DATABASE::"Assembly Header", DATABASE::"Transfer Line");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingIssuesTransferTransfer()
    begin
        RoundingIssuesRunScenario(DATABASE::"Transfer Line", DATABASE::"Transfer Line");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingIssuesTransferSale()
    begin
        RoundingIssuesRunScenario(DATABASE::"Sales Line", DATABASE::"Transfer Line");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingIssuesProdOrderCompILE()
    begin
        RoundingIssuesRunScenario(DATABASE::"Item Ledger Entry", DATABASE::"Prod. Order Component");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingIssuesProdOrderCompPurchase()
    begin
        RoundingIssuesRunScenario(DATABASE::"Purchase Line", DATABASE::"Prod. Order Component");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingIssuesProdOrderCompProduction()
    begin
        RoundingIssuesRunScenario(DATABASE::"Prod. Order Line", DATABASE::"Prod. Order Component");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingIssuesProdOrderCompAssembly()
    begin
        RoundingIssuesRunScenario(DATABASE::"Assembly Header", DATABASE::"Prod. Order Component");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingIssuesProdOrderCompTransfer()
    begin
        RoundingIssuesRunScenario(DATABASE::"Transfer Line", DATABASE::"Prod. Order Component");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingIssuesProdOrderCompSale()
    begin
        RoundingIssuesRunScenario(DATABASE::"Sales Line", DATABASE::"Prod. Order Component");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingIssuesPlanningCompILE()
    begin
        RoundingIssuesRunScenario(DATABASE::"Item Ledger Entry", DATABASE::"Planning Component");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingIssuesPlanningCompPurchase()
    begin
        RoundingIssuesRunScenario(DATABASE::"Purchase Line", DATABASE::"Planning Component");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingIssuesPlanningCompProduction()
    begin
        RoundingIssuesRunScenario(DATABASE::"Prod. Order Line", DATABASE::"Planning Component");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingIssuesPlanningCompAssembly()
    begin
        RoundingIssuesRunScenario(DATABASE::"Assembly Header", DATABASE::"Planning Component");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingIssuesPlanningCompTransfer()
    begin
        RoundingIssuesRunScenario(DATABASE::"Transfer Line", DATABASE::"Planning Component");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingIssuesPlanningCompSale()
    begin
        RoundingIssuesRunScenario(DATABASE::"Sales Line", DATABASE::"Planning Component");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingIssuesAsmLineILE()
    begin
        RoundingIssuesRunScenario(DATABASE::"Item Ledger Entry", DATABASE::"Assembly Line");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingIssuesAsmLinePurchase()
    begin
        RoundingIssuesRunScenario(DATABASE::"Purchase Line", DATABASE::"Assembly Line");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingIssuesAsmLineProduction()
    begin
        RoundingIssuesRunScenario(DATABASE::"Prod. Order Line", DATABASE::"Assembly Line");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingIssuesAsmLineAssembly()
    begin
        RoundingIssuesRunScenario(DATABASE::"Assembly Header", DATABASE::"Assembly Line");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingIssuesAsmLineTransfer()
    begin
        RoundingIssuesRunScenario(DATABASE::"Transfer Line", DATABASE::"Assembly Line");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingIssuesAsmLineSale()
    begin
        RoundingIssuesRunScenario(DATABASE::"Sales Line", DATABASE::"Assembly Line");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingIssuesServiceLineILE()
    begin
        RoundingIssuesRunScenario(DATABASE::"Item Ledger Entry", DATABASE::"Service Line");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingIssuesServiceLinePurchase()
    begin
        RoundingIssuesRunScenario(DATABASE::"Purchase Line", DATABASE::"Service Line");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingIssuesServiceLineProduction()
    begin
        RoundingIssuesRunScenario(DATABASE::"Prod. Order Line", DATABASE::"Service Line");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingIssuesServiceLineAssembly()
    begin
        RoundingIssuesRunScenario(DATABASE::"Assembly Header", DATABASE::"Service Line");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingIssuesServiceLineTransfer()
    begin
        RoundingIssuesRunScenario(DATABASE::"Transfer Line", DATABASE::"Service Line");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingIssuesServiceLineSale()
    begin
        RoundingIssuesRunScenario(DATABASE::"Sales Line", DATABASE::"Service Line");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingIssuesJobPlanningLineILE()
    begin
        RoundingIssuesRunScenario(DATABASE::"Item Ledger Entry", DATABASE::"Job Planning Line");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingIssuesJobPlanningLinePurchase()
    begin
        RoundingIssuesRunScenario(DATABASE::"Purchase Line", DATABASE::"Job Planning Line");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingIssuesJobPlanningLineProduction()
    begin
        RoundingIssuesRunScenario(DATABASE::"Prod. Order Line", DATABASE::"Job Planning Line");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingIssuesJobPlanningLineAssembly()
    begin
        RoundingIssuesRunScenario(DATABASE::"Assembly Header", DATABASE::"Job Planning Line");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingIssuesJobPlanningLineTransfer()
    begin
        RoundingIssuesRunScenario(DATABASE::"Transfer Line", DATABASE::"Job Planning Line");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingIssuesJobPlanningLineSale()
    begin
        RoundingIssuesRunScenario(DATABASE::"Sales Line", DATABASE::"Job Planning Line");
    end;

    local procedure RoundingIssuesRunScenario(SupplySourceType: Option; DemandSourceType: Option)
    begin
        RoundingIssuesScenario(false, false, SupplySourceType, DemandSourceType);
        RoundingIssuesScenario(true, false, SupplySourceType, DemandSourceType);
        RoundingIssuesScenario(false, true, SupplySourceType, DemandSourceType);
        RoundingIssuesScenario(true, true, SupplySourceType, DemandSourceType);
    end;

    local procedure RoundingIssuesScenario(WithLot: Boolean; PreReserve: Boolean; SupplySourceType: Option; DemandSourceType: Option)
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        ItemUnitOfMeasureKG: Record "Item Unit of Measure";
        ItemUnitOfMeasureBAG: Record "Item Unit of Measure";
        ItemUnitOfMeasureCAS: Record "Item Unit of Measure";
        ReservMgt: Codeunit "Reservation Management";
        LocationCode: Code[10];
        LotNo: Code[10];
        FullAutoReservation: Boolean;
        ShipmentDate: Date;
        QtyToReserve: Decimal;
        QtyToReserveBase: Decimal;
        SourceSubType: Option;
        SourceID: Code[20];
        SourceRefNo: Integer;
        SourceProdOrderLineNo: Integer;
    begin
        Initialize();

        // Please refer to bug in VSTF 330787 for reference to the values.

        // SETUP: Create supply with diff. UOMs and then create demand to trigger rounding problem
        Item."No." := LibraryUtility.GenerateRandomCode(Item.FieldNo("No."), DATABASE::Item);
        RoundingIssuesItemUOM(ItemUnitOfMeasureKG, Item."No.",
          LibraryUtility.GenerateRandomCode(ItemUnitOfMeasureKG.FieldNo(Code), DATABASE::"Item Unit of Measure"), 1);
        Item."Base Unit of Measure" := ItemUnitOfMeasureKG.Code;
        RoundingIssuesItemUOM(ItemUnitOfMeasureBAG, Item."No.",
          LibraryUtility.GenerateRandomCode(ItemUnitOfMeasureBAG.FieldNo(Code), DATABASE::"Item Unit of Measure"), 0.45);
        RoundingIssuesItemUOM(ItemUnitOfMeasureCAS, Item."No.",
          LibraryUtility.GenerateRandomCode(ItemUnitOfMeasureCAS.FieldNo(Code), DATABASE::"Item Unit of Measure"), 10.8);
        if WithLot then begin
            ItemTrackingCode.Code := LibraryUtility.GenerateRandomCode(ItemTrackingCode.FieldNo(Code), DATABASE::"Item Tracking Code");
            ItemTrackingCode."Lot Specific Tracking" := true;
            ItemTrackingCode.Insert();
            Item."Item Category Code" := ItemTrackingCode.Code;
            LotNo := LibraryUtility.GenerateGUID();
        end;
        Item.Insert();
        LocationCode := LibraryUtility.GenerateGUID();

        // Create supply - 2 supplies for 4 BAG and 1 supply for 10 CAS
        // Furthermore in PreReserve cases when demand is reserved against the BAG, create the supply part of the pair.
        RoundingIssuesCreateSupply(SupplySourceType, ItemUnitOfMeasureBAG, ItemUnitOfMeasureCAS, LocationCode, LotNo, PreReserve);

        // Create demand - 1 demand for 10 CAS
        RoundingIssuesCreateDemand(DemandSourceType, ItemUnitOfMeasureCAS, 10, LocationCode, LotNo, ShipmentDate,
          QtyToReserve, QtyToReserveBase,
          SourceSubType, SourceID, SourceRefNo, SourceProdOrderLineNo,
          PreReserve);

        // EXERCISE: Reserve supply against demand
        RoundingIssuesSetDemandSource(ReservMgt, DemandSourceType, SourceSubType, SourceID, SourceRefNo, SourceProdOrderLineNo);
        if DemandSourceType <> DATABASE::"Planning Component" then begin
            ReservMgt.AutoReserve(FullAutoReservation, '', ShipmentDate, QtyToReserve, QtyToReserveBase);

            // VERIFY: Reserved Qty should be same as Sales Qty and it should be fully reserved
            Assert.IsTrue(FullAutoReservation, 'Demand should be fully reserved as there is enough qty available.');
            RoundingIssuesVerify(DemandSourceType, QtyToReserve, QtyToReserveBase);
        end else begin
            asserterror ReservMgt.AutoReserve(FullAutoReservation, '', ShipmentDate, QtyToReserve, QtyToReserveBase);
            Assert.ExpectedError(NotTrueDemandErr);
        end;
    end;

    local procedure RoundingIssuesItemUOM(var ItemUnitOfMeasure: Record "Item Unit of Measure"; ItemNo: Code[20]; UOMCode: Code[10]; QtyPerUOM: Decimal)
    begin
        Clear(ItemUnitOfMeasure);
        ItemUnitOfMeasure."Item No." := ItemNo;
        ItemUnitOfMeasure.Code := UOMCode;
        ItemUnitOfMeasure."Qty. per Unit of Measure" := QtyPerUOM;
        ItemUnitOfMeasure.Insert();
    end;

    local procedure RoundingIssuesCreateSupply(SourceType: Option; ItemUnitOfMeasureBAG: Record "Item Unit of Measure"; ItemUnitOfMeasureCAS: Record "Item Unit of Measure"; LocationCode: Code[10]; LotNo: Code[10]; PreReserve: Boolean)
    begin
        // The sequence of the below lines is important as this would create multiple or single reservations.
        // The objective is to arrange the supplies so that the reservation routine has to touch each line
        // before auto-reserve is completed- this will ensure the possibility of touching the correction code.
        case SourceType of
            DATABASE::"Item Ledger Entry":
                begin
                    RoundingIssuesCreateILE(ItemUnitOfMeasureBAG."Item No.", 4, ItemUnitOfMeasureBAG.Code, LocationCode, LotNo, PreReserve);
                    RoundingIssuesCreateILE(ItemUnitOfMeasureBAG."Item No.", 4, ItemUnitOfMeasureBAG.Code, LocationCode, LotNo, PreReserve);
                    RoundingIssuesCreateILE(ItemUnitOfMeasureCAS."Item No.", 10, ItemUnitOfMeasureCAS.Code, LocationCode, LotNo, false);
                end;
            DATABASE::"Purchase Line":
                begin
                    RoundingIssuesCreatePurchaseAsSupply(ItemUnitOfMeasureCAS."Item No.", 10, ItemUnitOfMeasureCAS.Code, LocationCode,
                      LotNo, false);
                    RoundingIssuesCreatePurchaseAsSupply(ItemUnitOfMeasureBAG."Item No.", 4, ItemUnitOfMeasureBAG.Code, LocationCode,
                      LotNo, PreReserve);
                    RoundingIssuesCreatePurchaseAsSupply(ItemUnitOfMeasureBAG."Item No.", 4, ItemUnitOfMeasureBAG.Code, LocationCode,
                      LotNo, PreReserve);
                end;
            DATABASE::"Prod. Order Line":
                begin
                    RoundingIssuesCreateProdOrder(ItemUnitOfMeasureCAS."Item No.", 10, ItemUnitOfMeasureCAS.Code, LocationCode, LotNo, false);
                    RoundingIssuesCreateProdOrder(ItemUnitOfMeasureBAG."Item No.", 4, ItemUnitOfMeasureBAG.Code, LocationCode, LotNo, PreReserve);
                    RoundingIssuesCreateProdOrder(ItemUnitOfMeasureBAG."Item No.", 4, ItemUnitOfMeasureBAG.Code, LocationCode, LotNo, PreReserve);
                end;
            DATABASE::"Assembly Header":
                begin
                    RoundingIssuesCreateAsmHeader(ItemUnitOfMeasureCAS."Item No.", 10, ItemUnitOfMeasureCAS.Code, LocationCode, LotNo, false);
                    RoundingIssuesCreateAsmHeader(ItemUnitOfMeasureBAG."Item No.", 4, ItemUnitOfMeasureBAG.Code, LocationCode, LotNo, PreReserve);
                    RoundingIssuesCreateAsmHeader(ItemUnitOfMeasureBAG."Item No.", 4, ItemUnitOfMeasureBAG.Code, LocationCode, LotNo, PreReserve);
                end;
            DATABASE::"Transfer Line":
                begin
                    RoundingIssuesCreateTransferAsSupply(ItemUnitOfMeasureCAS."Item No.", 10, ItemUnitOfMeasureCAS.Code, LocationCode,
                      LotNo, false);
                    RoundingIssuesCreateTransferAsSupply(ItemUnitOfMeasureBAG."Item No.", 4, ItemUnitOfMeasureBAG.Code, LocationCode,
                      LotNo, PreReserve);
                    RoundingIssuesCreateTransferAsSupply(ItemUnitOfMeasureBAG."Item No.", 4, ItemUnitOfMeasureBAG.Code, LocationCode,
                      LotNo, PreReserve);
                end;
            DATABASE::"Sales Line":
                begin
                    RoundingIssuesCreateSalesAsSupply(ItemUnitOfMeasureCAS."Item No.", 10, ItemUnitOfMeasureCAS.Code, LocationCode, LotNo, false);
                    RoundingIssuesCreateSalesAsSupply(ItemUnitOfMeasureBAG."Item No.", 4, ItemUnitOfMeasureBAG.Code, LocationCode,
                      LotNo, PreReserve);
                    RoundingIssuesCreateSalesAsSupply(ItemUnitOfMeasureBAG."Item No.", 4, ItemUnitOfMeasureBAG.Code, LocationCode,
                      LotNo, PreReserve);
                end;
        end;
    end;

    local procedure RoundingIssuesCreateDemand(SourceType: Option; ItemUnitOfMeasureCAS: Record "Item Unit of Measure"; Qty: Decimal; LocationCode: Code[10]; LotNo: Code[10]; var ShipmentDate: Date; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal; var SourceSubType: Option; var SourceID: Code[20]; var SourceRefNo: Integer; var SourceProdOrderLineNo: Integer; PreReserve: Boolean)
    begin
        // Create demand, Set item tracking if required, set source on Reservation Management codeunit
        case SourceType of
            DATABASE::"Sales Line":
                RoundingIssuesCreateSalesAsDemand(ItemUnitOfMeasureCAS, Qty, LocationCode, LotNo, ShipmentDate,
                  QtyToReserve, QtyToReserveBase, SourceSubType, SourceID, SourceRefNo, SourceProdOrderLineNo, PreReserve);
            DATABASE::"Purchase Line":
                RoundingIssuesCreatePurchaseAsDemand(ItemUnitOfMeasureCAS, Qty, LocationCode, LotNo, ShipmentDate,
                  QtyToReserve, QtyToReserveBase, SourceSubType, SourceID, SourceRefNo, SourceProdOrderLineNo, PreReserve);
            DATABASE::"Transfer Line":
                RoundingIssuesCreateTransferAsDemand(ItemUnitOfMeasureCAS, Qty, LocationCode, LotNo, ShipmentDate,
                  QtyToReserve, QtyToReserveBase, SourceSubType, SourceID, SourceRefNo, SourceProdOrderLineNo, PreReserve);
            DATABASE::"Prod. Order Component":
                RoundingIssuesCreateProdOrderComp(ItemUnitOfMeasureCAS, Qty, LocationCode, LotNo, ShipmentDate,
                  QtyToReserve, QtyToReserveBase, SourceSubType, SourceID, SourceRefNo, SourceProdOrderLineNo, PreReserve);
            DATABASE::"Planning Component":
                RoundingIssuesCreatePlanningComp(ItemUnitOfMeasureCAS, Qty, LocationCode, LotNo, ShipmentDate,
                  QtyToReserve, QtyToReserveBase, SourceSubType, SourceID, SourceRefNo, SourceProdOrderLineNo, PreReserve);
            DATABASE::"Assembly Line":
                RoundingIssuesCreateAsmLine(ItemUnitOfMeasureCAS, Qty, LocationCode, LotNo, ShipmentDate,
                  QtyToReserve, QtyToReserveBase, SourceSubType, SourceID, SourceRefNo, SourceProdOrderLineNo, PreReserve);
            DATABASE::"Service Line":
                RoundingIssuesCreateService(ItemUnitOfMeasureCAS, Qty, LocationCode, LotNo, ShipmentDate,
                  QtyToReserve, QtyToReserveBase, SourceSubType, SourceID, SourceRefNo, SourceProdOrderLineNo, PreReserve);
            DATABASE::"Job Planning Line":
                RoundingIssuesCreateJobPlanning(ItemUnitOfMeasureCAS, Qty, LocationCode, LotNo, ShipmentDate,
                  QtyToReserve, QtyToReserveBase, SourceSubType, SourceID, SourceRefNo, SourceProdOrderLineNo, PreReserve);
        end;
    end;

    local procedure RoundingIssuesSetDemandSource(var ReservMgt: Codeunit "Reservation Management"; SourceType: Option; SourceSubType: Option; SourceID: Code[20]; SourceRefNo: Integer; SourceProdOrderLineNo: Integer)
    var
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
        TransferLine: Record "Transfer Line";
        ProdOrderComponent: Record "Prod. Order Component";
        PlanningComponent: Record "Planning Component";
        AsmLine: Record "Assembly Line";
        ServiceLine: Record "Service Line";
        JobPlanningLine: Record "Job Planning Line";
    begin
        case SourceType of
            DATABASE::"Sales Line":
                begin
                    SalesLine.Get(SourceSubType, SourceID, SourceRefNo);
                    ReservMgt.SetReservSource(SalesLine);
                end;
            DATABASE::"Purchase Line":
                begin
                    PurchaseLine.Get(SourceSubType, SourceID, SourceRefNo);
                    ReservMgt.SetReservSource(PurchaseLine);
                end;
            DATABASE::"Transfer Line":
                begin
                    TransferLine.Get(SourceID, SourceRefNo);
                    ReservMgt.SetReservSource(TransferLine, "Transfer Direction"::Outbound); // 0 stands for outbound
                end;
            DATABASE::"Prod. Order Component":
                begin
                    ProdOrderComponent.Get(SourceSubType, SourceID, SourceProdOrderLineNo, SourceRefNo);
                    ReservMgt.SetReservSource(ProdOrderComponent);
                end;
            DATABASE::"Planning Component":
                begin
                    PlanningComponent.Get('', SourceID, SourceProdOrderLineNo, SourceRefNo);
                    ReservMgt.SetReservSource(PlanningComponent);
                end;
            DATABASE::"Assembly Line":
                begin
                    AsmLine.Get(SourceSubType, SourceID, SourceRefNo);
                    ReservMgt.SetReservSource(AsmLine);
                end;
            DATABASE::"Service Line":
                begin
                    ServiceLine.Get(SourceSubType, SourceID, SourceRefNo);
                    ReservMgt.SetReservSource(ServiceLine);
                end;
            DATABASE::"Job Planning Line":
                begin
                    JobPlanningLine.SetRange("Job No.", SourceID);
                    JobPlanningLine.FindLast();
                    ReservMgt.SetReservSource(JobPlanningLine);
                end;
        end;
    end;

    local procedure RoundingIssuesFindLastReservationToDemand(SourceType: Integer; var ReservationEntry: Record "Reservation Entry")
    begin
        ReservationEntry.SetRange(Positive, false);
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Reservation);
        ReservationEntry.SetRange("Source Type", SourceType);
        ReservationEntry.FindLast();
    end;

    local procedure RoundingIssuesCreateILE(ItemNo: Code[20]; Qty: Decimal; UOMCode: Code[10]; LocationCode: Code[10]; LotNo: Code[10]; CreateReservationEntry: Boolean)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemLedgerEntry2: Record "Item Ledger Entry";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        if ItemLedgerEntry2.FindLast() then
            ItemLedgerEntry."Entry No." := ItemLedgerEntry2."Entry No." + 1
        else
            ItemLedgerEntry."Entry No." := 1;
        ItemLedgerEntry."Item No." := ItemNo;
        ItemLedgerEntry."Entry Type" := ItemLedgerEntry."Entry Type"::"Positive Adjmt.";
        ItemLedgerEntry."Unit of Measure Code" := UOMCode;
        ItemUnitOfMeasure.Get(ItemNo, UOMCode);
        ItemLedgerEntry."Qty. per Unit of Measure" := ItemUnitOfMeasure."Qty. per Unit of Measure";
        ItemLedgerEntry.Quantity := Qty * ItemLedgerEntry."Qty. per Unit of Measure";
        ItemLedgerEntry."Remaining Quantity" := ItemLedgerEntry.Quantity;
        ItemLedgerEntry.Open := true;
        ItemLedgerEntry.Positive := true;
        ItemLedgerEntry."Location Code" := LocationCode;
        ItemLedgerEntry."Lot No." := LotNo;
        ItemLedgerEntry.Insert();

        if CreateReservationEntry then
            RoundingIssuesCreateReservationEntry(true, true, ItemNo, 0, ItemLedgerEntry.Quantity,
              DATABASE::"Item Ledger Entry", 0, '', ItemLedgerEntry."Entry No.", 0, '', ItemLedgerEntry."Qty. per Unit of Measure",
              LotNo, 0D);
    end;

    local procedure RoundingIssuesCreatePurchaseAsSupply(ItemNo: Code[20]; Qty: Decimal; UOMCode: Code[10]; LocationCode: Code[10]; LotNo: Code[10]; CreateReservationEntry: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseLine(PurchaseLine, ItemNo, UOMCode, Qty, LocationCode, PurchaseLine."Document Type"::Order, WorkDate());
        RoundingIssuesCreateReservationEntry(true, false, ItemNo, PurchaseLine.Quantity, PurchaseLine."Quantity (Base)",
          DATABASE::"Purchase Line", PurchaseLine."Document Type".AsInteger(), PurchaseLine."Document No.", PurchaseLine."Line No.", 0, '',
          PurchaseLine."Qty. per Unit of Measure", LotNo, PurchaseLine."Expected Receipt Date");

        if CreateReservationEntry then
            RoundingIssuesCreateReservationEntry(true, true, ItemNo, 0, PurchaseLine."Quantity (Base)",
              DATABASE::"Purchase Line", PurchaseLine."Document Type".AsInteger(), PurchaseLine."Document No.", PurchaseLine."Line No.",
              0, '', PurchaseLine."Qty. per Unit of Measure", LotNo, 0D);
    end;

    local procedure RoundingIssuesCreatePurchaseAsDemand(ItemUnitOfMeasureCAS: Record "Item Unit of Measure"; Qty: Decimal; LocationCode: Code[10]; LotNo: Code[10]; var ShipmentDate: Date; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal; var SourceSubType: Option; var SourceID: Code[20]; var SourceRefNo: Integer; var SourceProdOrderLineNo: Integer; CreateReservationEntry: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseLine(PurchaseLine,
          ItemUnitOfMeasureCAS."Item No.", ItemUnitOfMeasureCAS.Code, Qty, LocationCode,
          PurchaseLine."Document Type"::"Return Order", WorkDate());

        if CreateReservationEntry then
            RoundingIssuesCreateReservationEntry(false, true, PurchaseLine."No.", -PurchaseLine.Quantity, -PurchaseLine."Quantity (Base)",
              DATABASE::"Purchase Line", PurchaseLine."Document Type".AsInteger(), PurchaseLine."Document No.", PurchaseLine."Line No.", 0, '',
              PurchaseLine."Qty. per Unit of Measure", LotNo, PurchaseLine."Expected Receipt Date");

        RoundingIssuesCreateReservationEntry(false, false, PurchaseLine."No.", -PurchaseLine.Quantity, -PurchaseLine."Quantity (Base)",
          DATABASE::"Purchase Line", PurchaseLine."Document Type".AsInteger(), PurchaseLine."Document No.", PurchaseLine."Line No.", 0, '',
          PurchaseLine."Qty. per Unit of Measure", LotNo, PurchaseLine."Expected Receipt Date");

        ShipmentDate := PurchaseLine."Expected Receipt Date";
        QtyToReserve := PurchaseLine.Quantity;
        QtyToReserveBase := PurchaseLine."Quantity (Base)";
        SourceSubType := PurchaseLine."Document Type".AsInteger();
        SourceID := PurchaseLine."Document No.";
        SourceRefNo := PurchaseLine."Line No.";
        SourceProdOrderLineNo := 0;
    end;

    local procedure RoundingIssuesCreateProdOrder(ItemNo: Code[20]; Qty: Decimal; UOMCode: Code[10]; LocationCode: Code[10]; LotNo: Code[10]; CreateReservationEntry: Boolean)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        CreateProdOrderLine(ProdOrderLine, ItemNo, UOMCode, Qty, LocationCode, WorkDate());
        RoundingIssuesCreateReservationEntry(true, false, ItemNo, ProdOrderLine.Quantity, ProdOrderLine."Quantity (Base)",
          DATABASE::"Prod. Order Line", ProdOrderLine.Status.AsInteger(), ProdOrderLine."Prod. Order No.", 0, ProdOrderLine."Line No.", '',
          ProdOrderLine."Qty. per Unit of Measure", LotNo, ProdOrderLine."Due Date");

        if CreateReservationEntry then
            RoundingIssuesCreateReservationEntry(true, true, ItemNo, 0, ProdOrderLine."Quantity (Base)",
              DATABASE::"Prod. Order Line", ProdOrderLine.Status.AsInteger(), ProdOrderLine."Prod. Order No.", 0, ProdOrderLine."Line No.", '',
              ProdOrderLine."Qty. per Unit of Measure", LotNo, 0D);
    end;

    local procedure RoundingIssuesCreateProdOrderComp(ItemUnitOfMeasureCAS: Record "Item Unit of Measure"; Qty: Decimal; LocationCode: Code[10]; LotNo: Code[10]; var ShipmentDate: Date; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal; var SourceSubType: Option; var SourceID: Code[20]; var SourceRefNo: Integer; var SourceProdOrderLineNo: Integer; CreateReservationEntry: Boolean)
    var
        ProdOrderComp: Record "Prod. Order Component";
    begin
        CreateProdOrderComp(ProdOrderComp, ItemUnitOfMeasureCAS."Item No.", ItemUnitOfMeasureCAS.Code, Qty, LocationCode, WorkDate());

        if CreateReservationEntry then
            RoundingIssuesCreateReservationEntry(false, true, ProdOrderComp."Item No.", -ProdOrderComp.Quantity,
              -ProdOrderComp."Quantity (Base)",
              DATABASE::"Prod. Order Component", ProdOrderComp.Status.AsInteger(), ProdOrderComp."Prod. Order No.", ProdOrderComp."Line No.",
              ProdOrderComp."Prod. Order Line No.", '', ProdOrderComp."Qty. per Unit of Measure", LotNo, ProdOrderComp."Due Date");

        RoundingIssuesCreateReservationEntry(false, false, ProdOrderComp."Item No.", -ProdOrderComp.Quantity,
          -ProdOrderComp."Quantity (Base)",
          DATABASE::"Prod. Order Component", ProdOrderComp.Status.AsInteger(), ProdOrderComp."Prod. Order No.", ProdOrderComp."Line No.",
          ProdOrderComp."Prod. Order Line No.", '', ProdOrderComp."Qty. per Unit of Measure", LotNo, ProdOrderComp."Due Date");

        ShipmentDate := ProdOrderComp."Due Date";
        QtyToReserve := ProdOrderComp.Quantity;
        QtyToReserveBase := ProdOrderComp."Quantity (Base)";
        SourceSubType := ProdOrderComp.Status.AsInteger();
        SourceID := ProdOrderComp."Prod. Order No.";
        SourceRefNo := ProdOrderComp."Line No.";
        SourceProdOrderLineNo := ProdOrderComp."Prod. Order Line No.";
    end;

    local procedure RoundingIssuesCreatePlanningComp(ItemUnitOfMeasureCAS: Record "Item Unit of Measure"; Qty: Decimal; LocationCode: Code[10]; LotNo: Code[10]; var ShipmentDate: Date; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal; var SourceSubType: Option; var SourceID: Code[20]; var SourceRefNo: Integer; var SourceProdOrderLineNo: Integer; CreateReservationEntry: Boolean)
    var
        PlanningComp: Record "Planning Component";
    begin
        CreatePlanningComp(PlanningComp, ItemUnitOfMeasureCAS, Qty, LocationCode, WorkDate());

        if CreateReservationEntry then
            RoundingIssuesCreateReservationEntry(false, true, PlanningComp."Item No.", -PlanningComp.Quantity, -PlanningComp."Quantity (Base)",
              DATABASE::"Planning Component", 0, '', PlanningComp."Line No.",
              0, '', PlanningComp."Qty. per Unit of Measure", LotNo, PlanningComp."Due Date");

        RoundingIssuesCreateReservationEntry(false, false, PlanningComp."Item No.", -PlanningComp.Quantity, -PlanningComp."Quantity (Base)",
          DATABASE::"Planning Component", 0, '', PlanningComp."Line No.",
          0, '', PlanningComp."Qty. per Unit of Measure", LotNo, PlanningComp."Due Date");

        ShipmentDate := PlanningComp."Due Date";
        QtyToReserve := PlanningComp.Quantity;
        QtyToReserveBase := PlanningComp."Quantity (Base)";
        SourceSubType := 0;
        SourceID := '';
        SourceRefNo := PlanningComp."Line No.";
        SourceProdOrderLineNo := 0;
    end;

    local procedure RoundingIssuesCreateAsmHeader(ItemNo: Code[20]; Qty: Decimal; UOMCode: Code[10]; LocationCode: Code[10]; LotNo: Code[10]; CreateReservationEntry: Boolean)
    var
        AsmHeader: Record "Assembly Header";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        AsmHeader."Document Type" := AsmHeader."Document Type"::Order;
        AsmHeader."No." := LibraryUtility.GenerateGUID();
        AsmHeader."Item No." := ItemNo;
        AsmHeader."Unit of Measure Code" := UOMCode;
        ItemUnitOfMeasure.Get(ItemNo, UOMCode);
        AsmHeader."Qty. per Unit of Measure" := ItemUnitOfMeasure."Qty. per Unit of Measure";
        AsmHeader.Quantity := Qty;
        AsmHeader."Quantity (Base)" := Qty * AsmHeader."Qty. per Unit of Measure";
        AsmHeader."Remaining Quantity" := AsmHeader.Quantity;
        AsmHeader."Remaining Quantity (Base)" := AsmHeader."Quantity (Base)";
        AsmHeader."Due Date" := WorkDate();
        AsmHeader."Location Code" := LocationCode;
        AsmHeader.Insert();

        RoundingIssuesCreateReservationEntry(true, false, ItemNo, AsmHeader.Quantity, AsmHeader."Quantity (Base)",
          DATABASE::"Assembly Header", AsmHeader."Document Type".AsInteger(), AsmHeader."No.", 0, 0, '',
          AsmHeader."Qty. per Unit of Measure", LotNo, AsmHeader."Due Date");

        if CreateReservationEntry then
            RoundingIssuesCreateReservationEntry(true, true, ItemNo, 0, AsmHeader."Quantity (Base)",
              DATABASE::"Assembly Header", AsmHeader."Document Type".AsInteger(), AsmHeader."No.", 0, 0, '',
              AsmHeader."Qty. per Unit of Measure", LotNo, AsmHeader."Due Date");
    end;

    local procedure RoundingIssuesCreateAsmLine(ItemUnitOfMeasureCAS: Record "Item Unit of Measure"; Qty: Decimal; LocationCode: Code[10]; LotNo: Code[10]; var ShipmentDate: Date; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal; var SourceSubType: Option; var SourceID: Code[20]; var SourceRefNo: Integer; var SourceProdOrderLineNo: Integer; CreateReservationEntry: Boolean)
    var
        AsmLine: Record "Assembly Line";
        RecRef: RecordRef;
    begin
        AsmLine."Document Type" := AsmLine."Document Type"::Order;
        AsmLine."Document No." := LibraryUtility.GenerateGUID();
        RecRef.GetTable(AsmLine);
        AsmLine."Line No." := LibraryUtility.GetNewLineNo(RecRef, AsmLine.FieldNo("Line No."));
        AsmLine.Type := AsmLine.Type::Item;
        AsmLine."No." := ItemUnitOfMeasureCAS."Item No.";
        AsmLine."Unit of Measure Code" := ItemUnitOfMeasureCAS.Code;
        AsmLine."Qty. per Unit of Measure" := ItemUnitOfMeasureCAS."Qty. per Unit of Measure";
        AsmLine.Quantity := Qty;
        AsmLine."Quantity (Base)" := Qty * AsmLine."Qty. per Unit of Measure";
        AsmLine."Remaining Quantity" := AsmLine.Quantity;
        AsmLine."Remaining Quantity (Base)" := AsmLine."Quantity (Base)";
        AsmLine."Due Date" := WorkDate();
        AsmLine."Location Code" := LocationCode;
        AsmLine.Insert();

        if CreateReservationEntry then
            RoundingIssuesCreateReservationEntry(false, true, AsmLine."No.", -AsmLine.Quantity, -AsmLine."Quantity (Base)",
              DATABASE::"Assembly Line", AsmLine."Document Type".AsInteger(), AsmLine."Document No.", AsmLine."Line No.", 0, '',
              AsmLine."Qty. per Unit of Measure", LotNo, AsmLine."Due Date");

        RoundingIssuesCreateReservationEntry(false, false, AsmLine."No.", -AsmLine.Quantity, -AsmLine."Quantity (Base)",
          DATABASE::"Assembly Line", AsmLine."Document Type".AsInteger(), AsmLine."Document No.", AsmLine."Line No.", 0, '',
          AsmLine."Qty. per Unit of Measure", LotNo, AsmLine."Due Date");

        ShipmentDate := AsmLine."Due Date";
        QtyToReserve := AsmLine.Quantity;
        QtyToReserveBase := AsmLine."Quantity (Base)";
        SourceSubType := AsmLine."Document Type".AsInteger();
        SourceID := AsmLine."Document No.";
        SourceRefNo := AsmLine."Line No.";
        SourceProdOrderLineNo := 0;
    end;

    local procedure RoundingIssuesCreateTransferAsSupply(ItemNo: Code[20]; Qty: Decimal; UOMCode: Code[10]; LocationCode: Code[10]; LotNo: Code[10]; CreateReservationEntry: Boolean)
    var
        TransferLine: Record "Transfer Line";
    begin
        CreateTransferLine(TransferLine, ItemNo, UOMCode, Qty, LibraryUtility.GenerateGUID(), LocationCode, WorkDate(), 0D);

        RoundingIssuesCreateReservationEntry(true, false, ItemNo, TransferLine.Quantity, TransferLine."Quantity (Base)",
          DATABASE::"Transfer Line", 1, TransferLine."Document No.", TransferLine."Line No.", 0, '',
          TransferLine."Qty. per Unit of Measure", LotNo, TransferLine."Receipt Date");

        if CreateReservationEntry then
            RoundingIssuesCreateReservationEntry(true, true, ItemNo, 0, TransferLine."Quantity (Base)",
              DATABASE::"Transfer Line", 1, TransferLine."Document No.", TransferLine."Line No.", 0, '',
              TransferLine."Qty. per Unit of Measure", LotNo, TransferLine."Receipt Date");
    end;

    local procedure RoundingIssuesCreateTransferAsDemand(ItemUnitOfMeasureCAS: Record "Item Unit of Measure"; Qty: Decimal; LocationCode: Code[10]; LotNo: Code[10]; var ShipmentDate: Date; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal; var SourceSubType: Option; var SourceID: Code[20]; var SourceRefNo: Integer; var SourceProdOrderLineNo: Integer; CreateReservationEntry: Boolean)
    var
        TransferLine: Record "Transfer Line";
    begin
        CreateTransferLine(
          TransferLine, ItemUnitOfMeasureCAS."Item No.",
          ItemUnitOfMeasureCAS.Code, Qty, LocationCode, LibraryUtility.GenerateGUID(), 0D, WorkDate());

        if CreateReservationEntry then
            RoundingIssuesCreateReservationEntry(false, true, TransferLine."Item No.", -TransferLine.Quantity, -TransferLine."Quantity (Base)",
              DATABASE::"Transfer Line", 0, TransferLine."Document No.", TransferLine."Line No.", 0, '',
              TransferLine."Qty. per Unit of Measure", LotNo, TransferLine."Shipment Date");

        RoundingIssuesCreateReservationEntry(false, false, TransferLine."Item No.", -TransferLine.Quantity, -TransferLine."Quantity (Base)",
          DATABASE::"Transfer Line", 0, TransferLine."Document No.", TransferLine."Line No.", 0, '',
          TransferLine."Qty. per Unit of Measure", LotNo, TransferLine."Shipment Date");

        ShipmentDate := TransferLine."Shipment Date";
        QtyToReserve := TransferLine.Quantity;
        QtyToReserveBase := TransferLine."Quantity (Base)";
        SourceSubType := 0;
        SourceID := TransferLine."Document No.";
        SourceRefNo := TransferLine."Line No.";
        SourceProdOrderLineNo := 0;
    end;

    local procedure RoundingIssuesCreateSalesAsSupply(ItemNo: Code[20]; Qty: Decimal; UOMCode: Code[10]; LocationCode: Code[10]; LotNo: Code[10]; CreateReservationEntry: Boolean)
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSaleLine(SalesLine, SalesLine."Document Type"::"Return Order", ItemNo, UOMCode, Qty, LocationCode, WorkDate());
        RoundingIssuesCreateReservationEntry(true, false, ItemNo, SalesLine.Quantity, SalesLine."Quantity (Base)",
          DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.", 0, '',
          SalesLine."Qty. per Unit of Measure", LotNo, SalesLine."Shipment Date");

        if CreateReservationEntry then
            RoundingIssuesCreateReservationEntry(true, true, ItemNo, 0, SalesLine."Quantity (Base)",
              DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.", 0, '',
              SalesLine."Qty. per Unit of Measure", LotNo, SalesLine."Shipment Date");
    end;

    local procedure RoundingIssuesCreateSalesAsDemand(ItemUnitOfMeasureCAS: Record "Item Unit of Measure"; Qty: Decimal; LocationCode: Code[10]; LotNo: Code[10]; var ShipmentDate: Date; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal; var SourceSubType: Option; var SourceID: Code[20]; var SourceRefNo: Integer; var SourceProdOrderLineNo: Integer; CreateReservationEntry: Boolean)
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSaleLine(SalesLine, SalesLine."Document Type"::Order, ItemUnitOfMeasureCAS."Item No.",
          ItemUnitOfMeasureCAS.Code, Qty, LocationCode, WorkDate());

        if CreateReservationEntry then
            RoundingIssuesCreateReservationEntry(false, true, SalesLine."No.", -SalesLine.Quantity, -SalesLine."Quantity (Base)",
              DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.", 0, '',
              SalesLine."Qty. per Unit of Measure", LotNo, SalesLine."Shipment Date");

        RoundingIssuesCreateReservationEntry(false, false, SalesLine."No.", -SalesLine.Quantity, -SalesLine."Quantity (Base)",
          DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.", 0, '',
          SalesLine."Qty. per Unit of Measure", LotNo, SalesLine."Shipment Date");

        ShipmentDate := SalesLine."Shipment Date";
        QtyToReserve := SalesLine.Quantity;
        QtyToReserveBase := SalesLine."Quantity (Base)";
        SourceSubType := SalesLine."Document Type".AsInteger();
        SourceID := SalesLine."Document No.";
        SourceRefNo := SalesLine."Line No.";
        SourceProdOrderLineNo := 0;
    end;

    local procedure RoundingIssuesCreateService(ItemUnitOfMeasureCAS: Record "Item Unit of Measure"; Qty: Decimal; LocationCode: Code[10]; LotNo: Code[10]; var ShipmentDate: Date; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal; var SourceSubType: Option; var SourceID: Code[20]; var SourceRefNo: Integer; var SourceProdOrderLineNo: Integer; CreateReservationEntry: Boolean)
    var
        ServiceLine: Record "Service Line";
    begin
        CreateServiceLine(ServiceLine, ItemUnitOfMeasureCAS."Item No.", ItemUnitOfMeasureCAS.Code, Qty, LocationCode, WorkDate());

        if CreateReservationEntry then
            RoundingIssuesCreateReservationEntry(false, true, ServiceLine."No.", -ServiceLine.Quantity, -ServiceLine."Quantity (Base)",
              DATABASE::"Service Line", ServiceLine."Document Type".AsInteger(), ServiceLine."Document No.", ServiceLine."Line No.", 0, '',
              ServiceLine."Qty. per Unit of Measure", LotNo, ServiceLine."Needed by Date");

        RoundingIssuesCreateReservationEntry(false, false, ServiceLine."No.", -ServiceLine.Quantity, -ServiceLine."Quantity (Base)",
          DATABASE::"Service Line", ServiceLine."Document Type".AsInteger(), ServiceLine."Document No.", ServiceLine."Line No.", 0, '',
          ServiceLine."Qty. per Unit of Measure", LotNo, ServiceLine."Needed by Date");

        ShipmentDate := ServiceLine."Needed by Date";
        QtyToReserve := ServiceLine.Quantity;
        QtyToReserveBase := ServiceLine."Quantity (Base)";
        SourceSubType := ServiceLine."Document Type".AsInteger();
        SourceID := ServiceLine."Document No.";
        SourceRefNo := ServiceLine."Line No.";
        SourceProdOrderLineNo := 0;
    end;

    local procedure RoundingIssuesCreateJobPlanning(ItemUnitOfMeasureCAS: Record "Item Unit of Measure"; Qty: Decimal; LocationCode: Code[10]; LotNo: Code[10]; var ShipmentDate: Date; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal; var SourceSubType: Option; var SourceID: Code[20]; var SourceRefNo: Integer; var SourceProdOrderLineNo: Integer; CreateReservationEntry: Boolean)
    var
        JobPlanningLine: Record "Job Planning Line";
        RecRef: RecordRef;
    begin
        JobPlanningLine."Job No." := LibraryUtility.GenerateGUID();
        RecRef.GetTable(JobPlanningLine);
        JobPlanningLine."Line No." := LibraryUtility.GetNewLineNo(RecRef, JobPlanningLine.FieldNo("Line No."));
        JobPlanningLine.Status := JobPlanningLine.Status::Order;
        JobPlanningLine.Type := JobPlanningLine.Type::Item;
        JobPlanningLine."No." := ItemUnitOfMeasureCAS."Item No.";
        JobPlanningLine.Quantity := Qty;
        JobPlanningLine."Unit of Measure Code" := ItemUnitOfMeasureCAS.Code;
        JobPlanningLine."Qty. per Unit of Measure" := ItemUnitOfMeasureCAS."Qty. per Unit of Measure";
        JobPlanningLine."Quantity (Base)" := JobPlanningLine.Quantity * JobPlanningLine."Qty. per Unit of Measure";
        JobPlanningLine."Remaining Qty." := JobPlanningLine.Quantity;
        JobPlanningLine."Remaining Qty. (Base)" := JobPlanningLine."Quantity (Base)";
        JobPlanningLine."Planning Date" := WorkDate();
        JobPlanningLine."Location Code" := LocationCode;
        JobPlanningLine.Insert();

        if CreateReservationEntry then
            RoundingIssuesCreateReservationEntry(false, true, JobPlanningLine."No.", -JobPlanningLine.Quantity,
              -JobPlanningLine."Quantity (Base)",
              DATABASE::"Job Planning Line", JobPlanningLine.Status.AsInteger(), JobPlanningLine."Job No.",
              JobPlanningLine."Job Contract Entry No.", 0, '',
              JobPlanningLine."Qty. per Unit of Measure", LotNo, JobPlanningLine."Planning Date");

        RoundingIssuesCreateReservationEntry(false, false, JobPlanningLine."No.", -JobPlanningLine.Quantity,
          -JobPlanningLine."Quantity (Base)",
          DATABASE::"Job Planning Line", JobPlanningLine.Status.AsInteger(), JobPlanningLine."Job No.",
          JobPlanningLine."Job Contract Entry No.", 0, '',
          JobPlanningLine."Qty. per Unit of Measure", LotNo, JobPlanningLine."Planning Date");

        ShipmentDate := JobPlanningLine."Planning Date";
        QtyToReserve := JobPlanningLine.Quantity;
        QtyToReserveBase := JobPlanningLine."Quantity (Base)";
        SourceSubType := JobPlanningLine.Status.AsInteger();
        SourceID := JobPlanningLine."Job No.";
        SourceRefNo := JobPlanningLine."Job Contract Entry No.";
        SourceProdOrderLineNo := 0;
    end;

    local procedure RoundingIssuesCreateReservationEntry(Supply: Boolean; Reservation: Boolean; ItemNo: Code[20]; Quantity: Decimal; QuantityBase: Decimal; SourceType: Option; SourceSubType: Option; SourceID: Code[20]; SourceRefNo: Integer; SourceProdOrderLineNo: Integer; SourceBatchName: Code[10]; QtyPerUOM: Decimal; LotNo: Code[10]; ShipmentDate: Date)
    var
        ReservationEntry: Record "Reservation Entry";
        ReservationEntry2: Record "Reservation Entry";
    begin
        if (not Supply) and (not Reservation) then // if item tracking needs to be put for demand, lot no should be non-empty
            if LotNo = '' then
                exit;

        if (not Supply) and Reservation then begin // if demand needs pre-reservation, find supply side reservation entry and use it
            ReservationEntry2.SetRange(Positive, true);
            ReservationEntry2.SetRange("Item No.", ItemNo);
            ReservationEntry2.SetRange("Reservation Status", ReservationEntry2."Reservation Status"::Reservation);
            ReservationEntry2.FindSet();
            repeat
                // set correct values for supply side reservation
                ReservationEntry2.Quantity := Round(ReservationEntry2."Quantity (Base)" / QtyPerUOM, 0.00001);
                ReservationEntry2."Shipment Date" := ShipmentDate;
                ReservationEntry2.Modify();

                // create demand side reservation
                ReservationEntry := ReservationEntry2;
                RoundingIssuesSetValuesOnResEntry(ReservationEntry, Supply, -ReservationEntry2.Quantity,
                  -ReservationEntry2."Quantity (Base)",
                  SourceType, SourceSubType, SourceID, SourceRefNo, SourceProdOrderLineNo, SourceBatchName,
                  QtyPerUOM, LotNo, ShipmentDate);
            until ReservationEntry2.Next() = 0;

            exit;
        end;

        if ReservationEntry2.FindLast() then
            ReservationEntry."Entry No." := ReservationEntry2."Entry No." + 1
        else
            ReservationEntry."Entry No." := 1;
        ReservationEntry."Item No." := ItemNo;
        if Reservation then
            ReservationEntry."Reservation Status" := ReservationEntry."Reservation Status"::Reservation
        else
            ReservationEntry."Reservation Status" := ReservationEntry."Reservation Status"::Surplus;

        // if item tracking needs to be put for demand,
        // Reduce quantities by that which is already reserved against supply
        if (not Supply) and (not Reservation) then begin
            ReservationEntry2.SetRange("Reservation Status", ReservationEntry2."Reservation Status"::Reservation);
            ReservationEntry2.SetRange("Source Type", SourceType);
            ReservationEntry2.SetRange("Source Subtype", SourceSubType);
            ReservationEntry2.SetRange("Source ID", SourceID);
            ReservationEntry2.SetRange("Source Batch Name", SourceBatchName);
            ReservationEntry2.SetRange("Source Prod. Order Line", SourceProdOrderLineNo);
            ReservationEntry2.SetRange("Source Ref. No.", SourceRefNo);
            if ReservationEntry2.FindSet() then
                repeat
                    Quantity := Quantity - ReservationEntry2.Quantity;
                    QuantityBase := QuantityBase - ReservationEntry2."Quantity (Base)";
                until ReservationEntry2.Next() = 0;
        end;
        RoundingIssuesSetValuesOnResEntry(ReservationEntry, Supply, Quantity, QuantityBase,
          SourceType, SourceSubType, SourceID, SourceRefNo, SourceProdOrderLineNo, SourceBatchName,
          QtyPerUOM, LotNo, ShipmentDate);
    end;

    local procedure RoundingIssuesSetValuesOnResEntry(var ReservationEntry: Record "Reservation Entry"; Supply: Boolean; Quantity: Decimal; QuantityBase: Decimal; SourceType: Option; SourceSubType: Option; SourceID: Code[20]; SourceRefNo: Integer; SourceProdOrderLineNo: Integer; SourceBatchName: Code[10]; QtyPerUOM: Decimal; LotNo: Code[10]; ShipmentDate: Date)
    begin
        ReservationEntry.Positive := Supply;
        ReservationEntry."Quantity (Base)" := QuantityBase;
        ReservationEntry."Source Type" := SourceType;
        ReservationEntry."Source Subtype" := SourceSubType;
        ReservationEntry."Source ID" := SourceID;
        ReservationEntry."Source Ref. No." := SourceRefNo;
        ReservationEntry."Source Prod. Order Line" := SourceProdOrderLineNo;
        ReservationEntry."Source Batch Name" := SourceBatchName;
        ReservationEntry.Quantity := Quantity;
        ReservationEntry."Qty. per Unit of Measure" := QtyPerUOM;
        ReservationEntry."Lot No." := LotNo;
        ReservationEntry."Shipment Date" := ShipmentDate;
        ReservationEntry.Insert();
    end;

    local procedure RoundingIssuesVerify(SourceType: Option; Quantity: Decimal; QuantityBase: Decimal)
    var
        ReservationEntry: Record "Reservation Entry";
        ReservationEntry2: Record "Reservation Entry";
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
        TransferLine: Record "Transfer Line";
        ProdOrderComp: Record "Prod. Order Component";
        PlanningComp: Record "Planning Component";
        AsmLine: Record "Assembly Line";
        ServiceLine: Record "Service Line";
        JobPlanningLine: Record "Job Planning Line";
        ReservedQuantity: Decimal;
        ReservedQuantityBase: Decimal;
    begin
        RoundingIssuesFindLastReservationToDemand(SourceType, ReservationEntry);
        ReservationEntry2.SetRange("Source Type", ReservationEntry."Source Type");
        ReservationEntry2.SetRange("Source ID", ReservationEntry."Source ID");
        Assert.AreEqual(3, ReservationEntry2.Count,
          'There are 3 supply lines- so 3 reservations to be made, so rounding issue is covered');
        case SourceType of
            DATABASE::"Sales Line":
                begin
                    SalesLine.Get(ReservationEntry."Source Subtype", ReservationEntry."Source ID", ReservationEntry."Source Ref. No.");
                    SalesLine.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
                    ReservedQuantity := SalesLine."Reserved Quantity";
                    ReservedQuantityBase := SalesLine."Reserved Qty. (Base)";
                end;
            DATABASE::"Purchase Line":
                begin
                    PurchaseLine.Get(ReservationEntry."Source Subtype", ReservationEntry."Source ID", ReservationEntry."Source Ref. No.");
                    PurchaseLine.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
                    ReservedQuantity := PurchaseLine."Reserved Quantity";
                    ReservedQuantityBase := PurchaseLine."Reserved Qty. (Base)";
                end;
            DATABASE::"Transfer Line":
                begin
                    TransferLine.Get(ReservationEntry."Source ID", ReservationEntry."Source Ref. No.");
                    TransferLine.CalcFields("Reserved Quantity Outbnd.", "Reserved Qty. Outbnd. (Base)");
                    ReservedQuantity := TransferLine."Reserved Quantity Outbnd.";
                    ReservedQuantityBase := TransferLine."Reserved Qty. Outbnd. (Base)";
                end;
            DATABASE::"Prod. Order Component":
                begin
                    ProdOrderComp.Get(ReservationEntry."Source Subtype", ReservationEntry."Source ID",
                      ReservationEntry."Source Prod. Order Line", ReservationEntry."Source Ref. No.");
                    ProdOrderComp.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
                    ReservedQuantity := ProdOrderComp."Reserved Quantity";
                    ReservedQuantityBase := ProdOrderComp."Reserved Qty. (Base)";
                end;
            DATABASE::"Planning Component":
                begin
                    PlanningComp.Get(ReservationEntry."Source Subtype", ReservationEntry."Source ID",
                      ReservationEntry."Source Prod. Order Line", ReservationEntry."Source Ref. No.");
                    PlanningComp.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
                    ReservedQuantity := PlanningComp."Reserved Quantity";
                    ReservedQuantityBase := PlanningComp."Reserved Qty. (Base)";
                end;
            DATABASE::"Assembly Line":
                begin
                    AsmLine.Get(ReservationEntry."Source Subtype", ReservationEntry."Source ID", ReservationEntry."Source Ref. No.");
                    AsmLine.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
                    ReservedQuantity := AsmLine."Reserved Quantity";
                    ReservedQuantityBase := AsmLine."Reserved Qty. (Base)";
                end;
            DATABASE::"Service Line":
                begin
                    ServiceLine.Get(ReservationEntry."Source Subtype", ReservationEntry."Source ID", ReservationEntry."Source Ref. No.");
                    ServiceLine.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
                    ReservedQuantity := ServiceLine."Reserved Quantity";
                    ReservedQuantityBase := ServiceLine."Reserved Qty. (Base)";
                end;
            DATABASE::"Job Planning Line":
                begin
                    JobPlanningLine.SetRange("Job No.", ReservationEntry."Source ID");
                    JobPlanningLine.FindLast();
                    JobPlanningLine.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
                    ReservedQuantity := JobPlanningLine."Reserved Quantity";
                    ReservedQuantityBase := JobPlanningLine."Reserved Qty. (Base)";
                end;
        end;
        Assert.AreEqual(Quantity, Abs(ReservedQuantity), 'The reserved qty must not have a rounding problem.');
        Assert.AreEqual(QuantityBase, Abs(ReservedQuantityBase), 'The reserved qty. base must not have a rounding problem.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelReservationSaleILE()
    begin
        // Verify Dates on Reservation Entry when Supply is Item Ledger Entry and Demand is Sales line.
        VerifyDatesOnReservationEntryAfterCancelReservation(DATABASE::"Item Ledger Entry", DATABASE::"Sales Line");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelReservationPurchasePlanningComp()
    begin
        // Verify Dates on Reservation Entry when Supply is Purchase Line and Demand is Planning Component.
        VerifyDatesOnReservationEntryAfterCancelReservation(DATABASE::"Purchase Line", DATABASE::"Planning Component");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelReservationSaleProduction()
    begin
        // Verify Dates on Reservation Entry when Supply is Prod. Order line and Demand is Sales line.
        VerifyDatesOnReservationEntryAfterCancelReservation(DATABASE::"Prod. Order Line", DATABASE::"Sales Line");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelReservationTransferPurchase()
    begin
        // Verify Dates on Reservation Entry when Supply is Transfer line and Demand is Purchase line.
        VerifyDatesOnReservationEntryAfterCancelReservation(DATABASE::"Transfer Line", DATABASE::"Purchase Line");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelReservationPurchaseProduction()
    begin
        // Verify Dates on Reservation Entry when Supply is Prod. Order Line and Demand is Purchase Line.
        VerifyDatesOnReservationEntryAfterCancelReservation(DATABASE::"Prod. Order Line", DATABASE::"Purchase Line");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelReservationProdOrderCompILE()
    begin
        // Verify Dates on Reservation Entry when Supply is Item Ledger Entry and Demand is Prod. Order Component.
        VerifyDatesOnReservationEntryAfterCancelReservation(DATABASE::"Item Ledger Entry", DATABASE::"Prod. Order Component");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelReservationILEService()
    begin
        // Verify Dates on Reservation Entry when Supply is ILE and Demand is Service Line.
        VerifyDatesOnReservationEntryAfterCancelReservation(DATABASE::"Item Ledger Entry", DATABASE::"Service Line");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateProdOrderFromSalesOrderWithMultipleUOM()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesQuantity: Decimal;
        QtyPerUnitOfMeasure: Decimal;
    begin
        // Create Sales Order with a UOM and create Production Order from Sales Order with another UOM. Verify Reservation Entry.

        // Setup: Create Item (e.g., Base UOM is PCS), create a Unit of Measure (e.g., PALLET) with "Qty. per Unit of Measure" greater than 2.
        // Create Sales Order for the Item, the UOM on Sales Line is PALLET.
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreateItemUOMAndUpdateItem(Item, QtyPerUnitOfMeasure);
        SalesQuantity := LibraryRandom.RandDec(10, 2);
        CreateSalesOrder(SalesHeader, Item."No.", SalesQuantity);

        // Exercise: Create Prod. Order from Sales Order, the UOM on Prod. Order Line is PCS. Reservation Entries will be generated.
        CreateProductionOrderFromSalesOrder(SalesHeader);

        // Verify: Quantity in Reservation Entries are correct.
        VerifyQtyInReservationEntry(Item."No.", DATABASE::"Sales Line", -SalesQuantity);
        VerifyQtyInReservationEntry(Item."No.", DATABASE::"Prod. Order Line", Round(SalesQuantity * QtyPerUnitOfMeasure, 0.00001));
    end;

    [Test]
    [HandlerFunctions('AutoReservationPageHandler')]
    [Scope('OnPrem')]
    procedure ReserveSalesOrderFromILEWithMultipleUOM()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesQuantity: Decimal;
        QtyPerUnitOfMeasure: Decimal;
    begin
        // Increase Item's Inventory with a UOM, create Sales Order with another UOM and reserve from Item Ledger Entry. Verify Reservation Entry.

        // Setup: Create Item (e.g., Base UOM is PCS) and update its Inventory, create a Unit of Measure (e.g., PALLET) with
        // "Qty. per Unit of Measure" greater than 2. Create Sales Order for the Item, the UOM on Sales Line is PALLET.
        Initialize();
        CreateItemAndUpdateInventory(Item, LibraryRandom.RandDecInRange(50, 100, 2));
        Item.Get(Item."No."); // Need to get Item because the Inventory has been updated
        CreateItemUOMAndUpdateItem(Item, QtyPerUnitOfMeasure);
        SalesQuantity := Round(SelectItemInventory(Item."No.") / QtyPerUnitOfMeasure, 0.00001, '<');
        CreateSalesOrder(SalesHeader, Item."No.", SalesQuantity);

        // Exercise: Reserve from Item Ledger Entry for Sales Line, the UOM in Item Ledger Entry is PCS.
        ReservationFromSalesOrder(SalesHeader."No.");

        // Verify: Quantity in Reservation Entries are correct.
        VerifyQtyInReservationEntry(Item."No.", DATABASE::"Sales Line", -SalesQuantity);
        VerifyQtyInReservationEntry(Item."No.", DATABASE::"Item Ledger Entry", Round(SalesQuantity * QtyPerUnitOfMeasure, 0.00001));
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler2,AvailableAssemblyHeadersPageHandler')]
    [Scope('OnPrem')]
    procedure ReserveFromAssemblyLine()
    var
        Item: Record Item;
        AssemblyItem: Record Item;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        Quantity: Decimal;
    begin
        // [FEATURE] [Assembly] [Reservation] [Available - Assembly Header]
        // [SCENARIO] Can reserve from page "Available - Assembly Headers" when supply is Assembly Line

        // [GIVEN] Create Assembly Order with resulting Item "I" of Quantity "Q", set Due Date to workdate
        Initialize();
        CreateItemAndUpdateInventory(Item, LibraryRandom.RandIntInRange(100, 200));
        Quantity := LibraryRandom.RandIntInRange(10, 20);
        LibraryInventory.CreateItem(AssemblyItem);
        LibraryAssembly.CreateAssemblyHeader(
          AssemblyHeader, WorkDate(), AssemblyItem."No.", '', Quantity, '');
        LibraryAssembly.CreateAssemblyLine(
          AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, Item."No.", Item."Base Unit of Measure", Quantity, 1, '');

        // [GIVEN] Create Assembly Order with component of Item "I" of Quantity "Q", set Due Date to WorkDate() + 7 days
        LibraryAssembly.CreateAssemblyHeader(
          AssemblyHeader, CalcDate('<+7D>', WorkDate()), LibraryInventory.CreateItemNo(), '', Quantity, '');
        LibraryAssembly.CreateAssemblyLine(
          AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, AssemblyItem."No.", Item."Base Unit of Measure", Quantity, 1, '');

        // [WHEN] Reserve from page "Available - Assembly Headers"
        ReservationFromAssemblyOrder(AssemblyHeader."No.");

        // [THEN] Reservation Quantity equals to "Q"
        VerifyQtyInReservationEntry(AssemblyItem."No.", DATABASE::"Assembly Line", -Quantity);
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure ReserveSavedOnCustomerChangeWhenBlankShipDateInSalesHeader()
    var
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemNo: Code[20];
        TransactionDate: Date;
        Qty: Decimal;
    begin
        // [FEATURE] [Purchase Order] [Sales Order] [Reservation]
        // [SCENARIO 379402] In Sales Line and in Reservation Entry, Shipment Date shouldn't be changed after changing of "Sell-to Customer No.".

        Initialize();
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyBillToCustomerAddressNotificationId());
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyCustomerAddressNotificationId());
        LibraryWarehouse.CreateLocation(Location);
        ItemNo := LibraryInventory.CreateItemNo();
        Qty := LibraryRandom.RandInt(20);
        // [GIVEN] Date "TransactionDate" of Purchase and Sales more than WORKDATE.
        TransactionDate := WorkDate() + LibraryRandom.RandInt(30);
        // [GIVEN] Purchase Order with "Expected Receipt Date" = "TransactionDate".
        CreatePurchaseOrderWithExpectedReceiptDate(TransactionDate, Location.Code, ItemNo, Qty);
        // [GIVEN] Sales Order with Shipment Date = WORKDATE and Sales Line with Shipment Date = "TransactionDate".
        CreateSalesOrderWithShipmentDate(SalesHeader, SalesLine, TransactionDate, Location.Code, ItemNo, Qty);
        // [GIVEN] Reservation of Quantity for Item in Sales Line.
        ReservationFromSalesOrder(SalesHeader."No.");

        // [WHEN] Change "Sell-to Customer No." in Sales Order.
        SalesHeader.Validate("Sell-to Customer No.", CreateCustomerWithLocationCode(Location.Code));

        // [THEN] Shipment Date is not changed neither in Sales Line nor in Reservation Entry.
        SalesLine.Find();
        VerifyShipmentDate(TransactionDate, SalesLine);
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,ConfirmHandlerYes')]
    [TestPermissions(TestPermissions::NonRestrictive)]
    [Scope('OnPrem')]
    procedure SalesHeaderPermissions()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        VATPostingSetup: Record "VAT Posting Setup";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        Inventory: Decimal;
    begin
        // [FEATURE] [Permissions] [Sales] [Order]
        // [SCENARIO 293225] Sales Line re-creation with Reservation Entries set does not need direct permissions for table "Reservation Entry"
        Initialize();

        // [GIVEN] Sales Order with Sales Line and Reservation Entries set
        Inventory := LibraryRandom.RandDec(10, 2) + 100;
        CreateItemAndUpdateInventory(Item, Inventory);
        CreateSalesOrder(SalesHeader, Item."No.", Inventory);
        ReservationFromSalesOrder(SalesHeader."No.");

        // [GIVEN] Created VAT Business Posting Group "VB01"
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, Item."VAT Prod. Posting Group");

        // [GIVEN] Permission Sets "D365 Basic", "D365 Sales Doc, Edit"
        LibraryLowerPermissions.SetO365Basic();
        LibraryLowerPermissions.AddSalesDocsCreate();

        // [WHEN] Validate "VAT Bus. Posting Group" = "VB01" causes Sales Lines re-creation
        SalesHeader.Validate("VAT Bus. Posting Group", VATBusinessPostingGroup.Code);

        // [THEN] Sales Line re-created successfully
        SelectSalesLine(SalesLine, SalesHeader."No.");
        SalesLine.TestField("VAT Bus. Posting Group", VATBusinessPostingGroup.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UTCopyReservEntryToTemp()
    var
        ReservationEntry: Record "Reservation Entry";
        TempReservationEntry: Record "Reservation Entry" temporary;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLineReserve: Codeunit "Sales Line-Reserve";
    begin
        // [FEATURE] [UT] [Sales] [Order]
        // [SCENARIO 293255] "CopyReservEntryToTemp" copies the reservation entry to a temporary table and deletes the original

        // [GIVEN] Sales Line 10000 for Sales Order "SO"
        MockSalesOrder(SalesHeader);
        MockSalesLine(SalesLine, SalesHeader);

        // [GIVEN] Reservation Entry for the Sales Line
        MockReservEntry(ReservationEntry, SalesLine);

        // [WHEN] Call "CopyReservEntryToTemp" with a Temporary Reservation Entry table record for the Sales Line
        SalesLineReserve.CopyReservEntryToTemp(TempReservationEntry, SalesLine);

        // [THEN] Reservation Entry for the Sales Line exists in the Temporary Reservation Entry table
        Assert.IsTrue(
          SalesLineReserve.FindReservEntry(SalesLine, TempReservationEntry), 'Reservation entry should be copied to temporary');

        // [THEN] Original Reservation Entry for the Sales Line is deleted
        Assert.IsFalse(SalesLineReserve.FindReservEntry(SalesLine, ReservationEntry), 'Reservation entry should be deleted from table');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UTCopyReservEntryFromTemp()
    var
        ReservationEntry: Record "Reservation Entry";
        TempReservationEntry: Record "Reservation Entry" temporary;
        SalesHeader: Record "Sales Header";
        NewSalesLine: Record "Sales Line";
        OldSalesLine: Record "Sales Line";
        SalesLineReserve: Codeunit "Sales Line-Reserve";
    begin
        // [FEATURE] [UT] [Sales] [Order]
        // [SCENARIO 293255] "CopyReservEntryToTemp" copies the reservation entry from a temporary table to the database and deletes the temporary record

        // [GIVEN] Sales Line 10000 for Sales Order "SO"
        MockSalesOrder(SalesHeader);
        MockSalesLine(OldSalesLine, SalesHeader);

        // [GIVEN] Reservation Entry for the Sales Line 10000
        MockReservEntry(ReservationEntry, OldSalesLine);

        // [GIVEN] Reservation Entry Copied to the Temporary Reservation Entry
        SalesLineReserve.CopyReservEntryToTemp(TempReservationEntry, OldSalesLine);
        Assert.IsTrue(
          SalesLineReserve.FindReservEntry(OldSalesLine, TempReservationEntry), 'Reservation entry should be copied to temporary');
        Assert.IsFalse(SalesLineReserve.FindReservEntry(OldSalesLine, ReservationEntry), 'Reservation entry should be deleted from table');

        // [GIVEN] Sales Line 20000 for Sales Order "SO"
        MockSalesLine(NewSalesLine, SalesHeader);

        // [WHEN] Copy Reservation Entry from Temporary table for the Sales Line 20000
        SalesLineReserve.CopyReservEntryFromTemp(TempReservationEntry, OldSalesLine, NewSalesLine."Line No.");

        // [THEN] Reservation Entry copied for the Sales Line 20000
        Assert.IsTrue(SalesLineReserve.FindReservEntry(NewSalesLine, ReservationEntry), 'Reservation entry should be inserted to table');

        // [THEN] Temporary Reservation Entry for the Sales Line 10000 deleted
        Assert.IsFalse(
          SalesLineReserve.FindReservEntry(OldSalesLine, TempReservationEntry),
          'Reservation entry should be deleted from temporary table');
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Reservation");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        Clear(InitialInventory);  // Clear Global variables.
        Clear(ExpCurrentReservedQty);
        Clear(MessageCounter);
        Clear(OutputQuantity);

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Reservation");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        NoSeriesSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        LibraryInventory.ItemJournalSetup(ItemJournalTemplate, ItemJournalBatch);
        OutputJournalSetup();

        LibrarySetupStorage.SaveGeneralLedgerSetup();
        isInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Reservation");
    end;

    local procedure MockSalesOrder(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::Order;
        SalesHeader."No." := LibraryUtility.GenerateRandomCode(SalesHeader.FieldNo("No."), DATABASE::"Sales Header");
        SalesHeader.Insert();
    end;

    local procedure MockSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    var
        RecRef: RecordRef;
    begin
        SalesLine.Init();
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        RecRef.GetTable(SalesLine);
        SalesLine."Line No." := LibraryUtility.GetNewLineNo(RecRef, SalesLine.FieldNo("Line No."));
        SalesLine.Insert();
    end;

    local procedure MockReservEntry(var ReservationEntry: Record "Reservation Entry"; SalesLine: Record "Sales Line")
    begin
        ReservationEntry.Init();
        ReservationEntry."Entry No." := LibraryUtility.GetNewRecNo(ReservationEntry, ReservationEntry.FieldNo("Entry No."));
        ReservationEntry.Positive := false;
        ReservationEntry."Source Type" := DATABASE::"Sales Line";
        ReservationEntry."Source Subtype" := SalesLine."Document Type".AsInteger();
        ReservationEntry."Source ID" := SalesLine."Document No.";
        ReservationEntry."Source Ref. No." := SalesLine."Line No.";
        ReservationEntry.Insert();
    end;

    local procedure NoSeriesSetup()
    begin
        LibrarySales.SetOrderNoSeriesInSetup();
        LibraryPurchase.SetOrderNoSeriesInSetup();
    end;

    local procedure OutputJournalSetup()
    begin
        Clear(OutputItemJournalTemplate);
        OutputItemJournalTemplate.Init();
        LibraryInventory.SelectItemJournalTemplateName(OutputItemJournalTemplate, OutputItemJournalTemplate.Type::Output);

        Clear(OutputItemJournalBatch);
        OutputItemJournalBatch.Init();
        LibraryInventory.SelectItemJournalBatchName(
          OutputItemJournalBatch, OutputItemJournalTemplate.Type, OutputItemJournalTemplate.Name);
    end;

    local procedure UpdateSalesReceivablesSetup(StockoutWarning: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Stockout Warning", StockoutWarning);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure CreateCustomerWithLocationCode(LocationCode: Code[10]): Code[10]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Location Code", LocationCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateItemWithLotSpecificTracking(var Item: Record Item; var ItemUnitOfMeasure: Record "Item Unit of Measure")
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        Item."No." := LibraryUtility.GenerateRandomCode(Item.FieldNo("No."), DATABASE::Item);
        RoundingIssuesItemUOM(
          ItemUnitOfMeasure, Item."No.",
          LibraryUtility.GenerateRandomCode(
            ItemUnitOfMeasure.FieldNo(Code), DATABASE::"Item Unit of Measure"), LibraryRandom.RandDec(10, 2));
        ItemTrackingCode.Code := LibraryUtility.GenerateRandomCode(ItemTrackingCode.FieldNo(Code), DATABASE::"Item Tracking Code");
        ItemTrackingCode."Lot Specific Tracking" := true;
        ItemTrackingCode.Insert();
        Item."Item Tracking Code" := ItemTrackingCode.Code;
        Item."Base Unit of Measure" := ItemUnitOfMeasure.Code;
        Item.Insert();
    end;

    local procedure CreateSupply(SourceType: Option; ItemUnitOfMeasure: Record "Item Unit of Measure"; LocationCode: Code[10]; LotNo: Code[10]; ExpectedReceiptDate: Date; Quantity: Decimal)
    begin
        case SourceType of
            DATABASE::"Item Ledger Entry":
                RoundingIssuesCreateILE(ItemUnitOfMeasure."Item No.", Quantity, ItemUnitOfMeasure.Code, LocationCode, LotNo, true);
            DATABASE::"Purchase Line":
                CreatePurchaseAsSupply(ItemUnitOfMeasure."Item No.", Quantity, ItemUnitOfMeasure.Code, LocationCode, LotNo, ExpectedReceiptDate);
            DATABASE::"Prod. Order Line":
                CreateProdOrderAsSupply(ItemUnitOfMeasure."Item No.", Quantity, ItemUnitOfMeasure.Code, LocationCode, LotNo, ExpectedReceiptDate);
            DATABASE::"Transfer Line":
                CreateTransferAsSupply(ItemUnitOfMeasure."Item No.", Quantity, ItemUnitOfMeasure.Code, LocationCode, LotNo, ExpectedReceiptDate);
            DATABASE::"Sales Line":
                CreateSalesAsSupply(ItemUnitOfMeasure."Item No.", Quantity, ItemUnitOfMeasure.Code, LocationCode, LotNo, ExpectedReceiptDate);
        end;
    end;

    local procedure CreateDemand(SourceType: Option; ItemUnitOfMeasureCAS: Record "Item Unit of Measure"; Qty: Decimal; LocationCode: Code[10]; LotNo: Code[10]; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal; var SourceSubType: Option; var SourceID: Code[20]; var SourceRefNo: Integer; var SourceProdOrderLineNo: Integer; ShipmentDate: Date)
    begin
        case SourceType of
            DATABASE::"Sales Line":
                CreateSalesAsDemand(ItemUnitOfMeasureCAS, Qty, LocationCode, LotNo,
                  QtyToReserve, QtyToReserveBase, SourceSubType, SourceID, SourceRefNo, SourceProdOrderLineNo, ShipmentDate);
            DATABASE::"Purchase Line":
                CreatePurchaseAsDemand(ItemUnitOfMeasureCAS, Qty, LocationCode, LotNo,
                  QtyToReserve, QtyToReserveBase, SourceSubType, SourceID, SourceRefNo, SourceProdOrderLineNo, ShipmentDate);
            DATABASE::"Transfer Line":
                CreateTransferAsDemand(ItemUnitOfMeasureCAS, Qty, LocationCode, LotNo,
                  QtyToReserve, QtyToReserveBase, SourceSubType, SourceID, SourceRefNo, SourceProdOrderLineNo, ShipmentDate);
            DATABASE::"Prod. Order Component":
                CreateProdOrderCompAsdemand(ItemUnitOfMeasureCAS, Qty, LocationCode, LotNo,
                  QtyToReserve, QtyToReserveBase, SourceSubType, SourceID, SourceRefNo, SourceProdOrderLineNo, ShipmentDate);
            DATABASE::"Planning Component":
                CreatePlanningCompAsDemand(ItemUnitOfMeasureCAS, Qty, LocationCode, LotNo,
                  QtyToReserve, QtyToReserveBase, SourceSubType, SourceID, SourceRefNo, SourceProdOrderLineNo, ShipmentDate);
            DATABASE::"Service Line":
                CreateServiceAsDemand(ItemUnitOfMeasureCAS, Qty, LocationCode, LotNo,
                  QtyToReserve, QtyToReserveBase, SourceSubType, SourceID, SourceRefNo, SourceProdOrderLineNo, ShipmentDate);
        end;
    end;

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; UOMCode: Code[10]; Qty: Decimal; LocationCode: Code[10]; DocumentType: Enum "Purchase Document Type"; ExpectedReceiptDate: Date)
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        RecRef: RecordRef;
    begin
        PurchaseLine."Document Type" := DocumentType;
        PurchaseLine."Document No." := LibraryUtility.GenerateGUID();
        RecRef.GetTable(PurchaseLine);
        PurchaseLine."Line No." := LibraryUtility.GetNewLineNo(RecRef, PurchaseLine.FieldNo("Line No."));
        PurchaseLine.Type := PurchaseLine.Type::Item;
        PurchaseLine."No." := ItemNo;
        PurchaseLine."Unit of Measure Code" := UOMCode;
        ItemUnitOfMeasure.Get(ItemNo, UOMCode);
        PurchaseLine."Qty. per Unit of Measure" := ItemUnitOfMeasure."Qty. per Unit of Measure";
        PurchaseLine.Quantity := Qty;
        PurchaseLine."Quantity (Base)" := Qty * PurchaseLine."Qty. per Unit of Measure";
        PurchaseLine."Outstanding Quantity" := PurchaseLine.Quantity;
        PurchaseLine."Outstanding Qty. (Base)" := PurchaseLine."Quantity (Base)";
        PurchaseLine."Expected Receipt Date" := ExpectedReceiptDate;
        PurchaseLine."Location Code" := LocationCode;
        PurchaseLine.Insert();
    end;

    local procedure CreatePurchaseOrderWithExpectedReceiptDate(ExpectedReceiptDate: Date; LocationCode: Code[10]; ItemNo: Code[20]; Qty: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Qty);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Validate("Expected Receipt Date", ExpectedReceiptDate);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ItemNo: Code[20]; UOMCode: Code[10]; Qty: Decimal; LocationCode: Code[10]; DueDate: Date)
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        RecRef: RecordRef;
    begin
        ProdOrderLine.Status := ProdOrderLine.Status::"Firm Planned";
        ProdOrderLine."Prod. Order No." := LibraryUtility.GenerateGUID();
        RecRef.GetTable(ProdOrderLine);
        ProdOrderLine."Line No." := LibraryUtility.GetNewLineNo(RecRef, ProdOrderLine.FieldNo("Line No."));
        ProdOrderLine."Item No." := ItemNo;
        ProdOrderLine."Unit of Measure Code" := UOMCode;
        ItemUnitOfMeasure.Get(ItemNo, UOMCode);
        ProdOrderLine."Qty. per Unit of Measure" := ItemUnitOfMeasure."Qty. per Unit of Measure";
        ProdOrderLine.Quantity := Qty;
        ProdOrderLine."Quantity (Base)" := Qty * ProdOrderLine."Qty. per Unit of Measure";
        ProdOrderLine."Remaining Quantity" := ProdOrderLine.Quantity;
        ProdOrderLine."Remaining Qty. (Base)" := ProdOrderLine."Quantity (Base)";
        ProdOrderLine."Due Date" := DueDate;
        ProdOrderLine."Location Code" := LocationCode;
        ProdOrderLine.Insert();
    end;

    local procedure CreateTransferLine(var TransferLine: Record "Transfer Line"; ItemNo: Code[20]; UOMCode: Code[10]; Qty: Decimal; TransferFromCode: Code[10]; TransferToCode: Code[10]; ReceiptDate: Date; ShipmentDate: Date)
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        RecRef: RecordRef;
    begin
        TransferLine."Document No." := LibraryUtility.GenerateGUID();
        RecRef.GetTable(TransferLine);
        TransferLine."Line No." := LibraryUtility.GetNewLineNo(RecRef, TransferLine.FieldNo("Line No."));
        TransferLine."Item No." := ItemNo;
        TransferLine."Unit of Measure Code" := UOMCode;
        ItemUnitOfMeasure.Get(ItemNo, UOMCode);
        TransferLine."Qty. per Unit of Measure" := ItemUnitOfMeasure."Qty. per Unit of Measure";
        TransferLine.Quantity := Qty;
        TransferLine."Quantity (Base)" := Qty * TransferLine."Qty. per Unit of Measure";
        TransferLine."Outstanding Quantity" := TransferLine.Quantity;
        TransferLine."Outstanding Qty. (Base)" := TransferLine."Quantity (Base)";
        TransferLine."Receipt Date" := ReceiptDate;
        TransferLine."Shipment Date" := ShipmentDate;
        TransferLine."Transfer-from Code" := TransferFromCode;
        TransferLine."Transfer-to Code" := TransferToCode;
        TransferLine.Insert();
    end;

    local procedure CreateSaleLine(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; ItemNo: Code[20]; UOMCode: Code[10]; Qty: Decimal; LocationCode: Code[10]; ShipmentDate: Date)
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        RecRef: RecordRef;
    begin
        SalesLine."Document Type" := DocumentType;
        SalesLine."Document No." := LibraryUtility.GenerateGUID();
        RecRef.GetTable(SalesLine);
        SalesLine."Line No." := LibraryUtility.GetNewLineNo(RecRef, SalesLine.FieldNo("Line No."));
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine."No." := ItemNo;
        SalesLine.Quantity := Qty;
        SalesLine."Unit of Measure Code" := ItemUnitOfMeasure.Code;
        ItemUnitOfMeasure.Get(ItemNo, UOMCode);
        SalesLine."Qty. per Unit of Measure" := ItemUnitOfMeasure."Qty. per Unit of Measure";
        SalesLine."Quantity (Base)" := SalesLine.Quantity * SalesLine."Qty. per Unit of Measure";
        SalesLine."Outstanding Quantity" := SalesLine.Quantity;
        SalesLine."Outstanding Qty. (Base)" := SalesLine."Quantity (Base)";
        SalesLine."Shipment Date" := ShipmentDate;
        SalesLine."Location Code" := LocationCode;
        SalesLine.Insert();
    end;

    local procedure CreateSalesOrderWithShipmentDate(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ShipmentDate: Date; LocationCode: Code[10]; ItemNo: Code[20]; Qty: Decimal)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Location Code", LocationCode);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Qty);
        SalesLine.Validate("Shipment Date", ShipmentDate);
        SalesLine.Modify(true);
    end;

    local procedure CreateProdOrderComp(var ProdOrderComp: Record "Prod. Order Component"; ItemNo: Code[20]; UOMCode: Code[10]; Qty: Decimal; LocationCode: Code[10]; DueDate: Date)
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        RecRef: RecordRef;
    begin
        ProdOrderComp.Status := ProdOrderComp.Status::"Firm Planned";
        ProdOrderComp."Prod. Order No." := LibraryUtility.GenerateGUID();
        RecRef.GetTable(ProdOrderComp);
        ProdOrderComp."Prod. Order Line No." := LibraryUtility.GetNewLineNo(RecRef, ProdOrderComp.FieldNo("Prod. Order Line No."));
        ProdOrderComp."Line No." := LibraryUtility.GetNewLineNo(RecRef, ProdOrderComp.FieldNo("Line No."));
        ProdOrderComp."Item No." := ItemNo;
        ItemUnitOfMeasure.Get(ItemNo, UOMCode);
        ProdOrderComp."Unit of Measure Code" := ItemUnitOfMeasure.Code;
        ProdOrderComp."Qty. per Unit of Measure" := ItemUnitOfMeasure."Qty. per Unit of Measure";
        ProdOrderComp.Quantity := Qty;
        ProdOrderComp."Quantity (Base)" := Qty * ProdOrderComp."Qty. per Unit of Measure";
        ProdOrderComp."Remaining Quantity" := ProdOrderComp.Quantity;
        ProdOrderComp."Remaining Qty. (Base)" := ProdOrderComp."Quantity (Base)";
        ProdOrderComp."Due Date" := DueDate;
        ProdOrderComp."Location Code" := LocationCode;
        ProdOrderComp.Insert();
    end;

    local procedure CreatePlanningComp(var PlanningComp: Record "Planning Component"; ItemUnitOfMeasure: Record "Item Unit of Measure"; Qty: Decimal; LocationCode: Code[10]; DueDate: Date)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(PlanningComp);
        PlanningComp."Line No." := LibraryUtility.GetNewLineNo(RecRef, PlanningComp.FieldNo("Line No."));
        PlanningComp."Item No." := ItemUnitOfMeasure."Item No.";
        PlanningComp."Unit of Measure Code" := ItemUnitOfMeasure.Code;
        PlanningComp."Qty. per Unit of Measure" := ItemUnitOfMeasure."Qty. per Unit of Measure";
        PlanningComp.Quantity := Qty;
        PlanningComp."Quantity (Base)" := Qty * PlanningComp."Qty. per Unit of Measure";
        PlanningComp."Net Quantity (Base)" := PlanningComp."Quantity (Base)";
        PlanningComp."Due Date" := DueDate;
        PlanningComp."Location Code" := LocationCode;
        PlanningComp.Insert();
    end;

    local procedure CreateServiceLine(var ServiceLine: Record "Service Line"; ItemNo: Code[20]; UOMCode: Code[10]; Qty: Decimal; LocationCode: Code[10]; NeedByDate: Date)
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        RecRef: RecordRef;
    begin
        ServiceLine."Document Type" := ServiceLine."Document Type"::Order;
        ServiceLine."Document No." := LibraryUtility.GenerateGUID();
        RecRef.GetTable(ServiceLine);
        ServiceLine."Line No." := LibraryUtility.GetNewLineNo(RecRef, ServiceLine.FieldNo("Line No."));
        ServiceLine.Type := ServiceLine.Type::Item;
        ServiceLine."No." := ItemNo;
        ServiceLine.Quantity := Qty;
        ItemUnitOfMeasure.Get(ItemNo, UOMCode);
        ServiceLine."Unit of Measure Code" := ItemUnitOfMeasure.Code;
        ServiceLine."Qty. per Unit of Measure" := ItemUnitOfMeasure."Qty. per Unit of Measure";
        ServiceLine."Quantity (Base)" := ServiceLine.Quantity * ServiceLine."Qty. per Unit of Measure";
        ServiceLine."Outstanding Quantity" := ServiceLine.Quantity;
        ServiceLine."Outstanding Qty. (Base)" := ServiceLine."Quantity (Base)";
        ServiceLine."Needed by Date" := NeedByDate;
        ServiceLine."Location Code" := LocationCode;
        ServiceLine.Insert();
    end;

    local procedure CreatePurchaseAsSupply(ItemNo: Code[20]; Qty: Decimal; UOMCode: Code[10]; LocationCode: Code[10]; LotNo: Code[10]; ExpectedReceiptDate: Date)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseLine(PurchaseLine, ItemNo, UOMCode, Qty, LocationCode, PurchaseLine."Document Type"::Order, ExpectedReceiptDate);
        RoundingIssuesCreateReservationEntry(true, true, ItemNo, 0, PurchaseLine."Quantity (Base)",
          DATABASE::"Purchase Line", PurchaseLine."Document Type".AsInteger(), PurchaseLine."Document No.", PurchaseLine."Line No.",
          0, '', PurchaseLine."Qty. per Unit of Measure", LotNo, PurchaseLine."Expected Receipt Date");
    end;

    local procedure CreatePurchaseAsDemand(ItemUnitOfMeasureCAS: Record "Item Unit of Measure"; Qty: Decimal; LocationCode: Code[10]; LotNo: Code[10]; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal; var SourceSubType: Option; var SourceID: Code[20]; var SourceRefNo: Integer; var SourceProdOrderLineNo: Integer; ExpectedReceiptDate: Date)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseLine(PurchaseLine,
          ItemUnitOfMeasureCAS."Item No.", ItemUnitOfMeasureCAS.Code, Qty,
          LocationCode, PurchaseLine."Document Type"::Order, ExpectedReceiptDate);
        RoundingIssuesCreateReservationEntry(false, true, PurchaseLine."No.", -PurchaseLine.Quantity, -PurchaseLine."Quantity (Base)",
          DATABASE::"Purchase Line", PurchaseLine."Document Type".AsInteger(), PurchaseLine."Document No.", PurchaseLine."Line No.", 0, '',
          PurchaseLine."Qty. per Unit of Measure", LotNo, PurchaseLine."Expected Receipt Date");

        QtyToReserve := PurchaseLine.Quantity;
        QtyToReserveBase := PurchaseLine."Quantity (Base)";
        SourceSubType := PurchaseLine."Document Type".AsInteger();
        SourceID := PurchaseLine."Document No.";
        SourceRefNo := PurchaseLine."Line No.";
        SourceProdOrderLineNo := 0;
    end;

    local procedure CreateProdOrderAsSupply(ItemNo: Code[20]; Qty: Decimal; UOMCode: Code[10]; LocationCode: Code[10]; LotNo: Code[10]; DueDate: Date)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        CreateProdOrderLine(ProdOrderLine, ItemNo, UOMCode, Qty, LocationCode, DueDate);
        RoundingIssuesCreateReservationEntry(true, true, ItemNo, 0, ProdOrderLine."Quantity (Base)",
          DATABASE::"Prod. Order Line", ProdOrderLine.Status.AsInteger(), ProdOrderLine."Prod. Order No.", 0, ProdOrderLine."Line No.", '',
          ProdOrderLine."Qty. per Unit of Measure", LotNo, ProdOrderLine."Due Date");
    end;

    local procedure CreateProdOrderCompAsdemand(ItemUnitOfMeasureCAS: Record "Item Unit of Measure"; Qty: Decimal; LocationCode: Code[10]; LotNo: Code[10]; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal; var SourceSubType: Option; var SourceID: Code[20]; var SourceRefNo: Integer; var SourceProdOrderLineNo: Integer; DueDate: Date)
    var
        ProdOrderComp: Record "Prod. Order Component";
    begin
        CreateProdOrderComp(ProdOrderComp, ItemUnitOfMeasureCAS."Item No.", ItemUnitOfMeasureCAS.Code, Qty, LocationCode, DueDate);
        RoundingIssuesCreateReservationEntry(false, true, ProdOrderComp."Item No.", -ProdOrderComp.Quantity,
          -ProdOrderComp."Quantity (Base)",
          DATABASE::"Prod. Order Component", ProdOrderComp.Status.AsInteger(), ProdOrderComp."Prod. Order No.", ProdOrderComp."Line No.",
          ProdOrderComp."Prod. Order Line No.", '', ProdOrderComp."Qty. per Unit of Measure", LotNo, ProdOrderComp."Due Date");

        QtyToReserve := ProdOrderComp.Quantity;
        QtyToReserveBase := ProdOrderComp."Quantity (Base)";
        SourceSubType := ProdOrderComp.Status.AsInteger();
        SourceID := ProdOrderComp."Prod. Order No.";
        SourceRefNo := ProdOrderComp."Line No.";
        SourceProdOrderLineNo := ProdOrderComp."Prod. Order Line No.";
    end;

    local procedure CreatePlanningCompAsDemand(ItemUnitOfMeasureCAS: Record "Item Unit of Measure"; Qty: Decimal; LocationCode: Code[10]; LotNo: Code[10]; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal; var SourceSubType: Option; var SourceID: Code[20]; var SourceRefNo: Integer; var SourceProdOrderLineNo: Integer; DueDate: Date)
    var
        PlanningComp: Record "Planning Component";
    begin
        CreatePlanningComp(PlanningComp, ItemUnitOfMeasureCAS, Qty, LocationCode, DueDate);
        RoundingIssuesCreateReservationEntry(false, true, PlanningComp."Item No.", -PlanningComp.Quantity, -PlanningComp."Quantity (Base)",
          DATABASE::"Planning Component", 0, '', PlanningComp."Line No.",
          0, '', PlanningComp."Qty. per Unit of Measure", LotNo, PlanningComp."Due Date");

        QtyToReserve := PlanningComp.Quantity;
        QtyToReserveBase := PlanningComp."Quantity (Base)";
        SourceSubType := 0;
        SourceID := '';
        SourceRefNo := PlanningComp."Line No.";
        SourceProdOrderLineNo := 0;
    end;

    local procedure CreateTransferAsSupply(ItemNo: Code[20]; Qty: Decimal; UOMCode: Code[10]; LocationCode: Code[10]; LotNo: Code[10]; ReceiptDate: Date)
    var
        TransferLine: Record "Transfer Line";
    begin
        CreateTransferLine(TransferLine, ItemNo, UOMCode, Qty, LibraryUtility.GenerateGUID(), LocationCode, ReceiptDate, 0D);
        RoundingIssuesCreateReservationEntry(true, true, ItemNo, 0, TransferLine."Quantity (Base)",
          DATABASE::"Transfer Line", 1, TransferLine."Document No.", TransferLine."Line No.", 0, '',
          TransferLine."Qty. per Unit of Measure", LotNo, TransferLine."Receipt Date");
    end;

    local procedure CreateTransferAsDemand(ItemUnitOfMeasureCAS: Record "Item Unit of Measure"; Qty: Decimal; LocationCode: Code[10]; LotNo: Code[10]; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal; var SourceSubType: Option; var SourceID: Code[20]; var SourceRefNo: Integer; var SourceProdOrderLineNo: Integer; ShipmentDate: Date)
    var
        TransferLine: Record "Transfer Line";
    begin
        CreateTransferLine(TransferLine,
          ItemUnitOfMeasureCAS."Item No.", ItemUnitOfMeasureCAS.Code, Qty, LocationCode, LibraryUtility.GenerateGUID(), 0D, ShipmentDate);
        RoundingIssuesCreateReservationEntry(false, true, TransferLine."Item No.", -TransferLine.Quantity, -TransferLine."Quantity (Base)",
          DATABASE::"Transfer Line", 0, TransferLine."Document No.", TransferLine."Line No.", 0, '',
          TransferLine."Qty. per Unit of Measure", LotNo, TransferLine."Shipment Date");

        QtyToReserve := TransferLine.Quantity;
        QtyToReserveBase := TransferLine."Quantity (Base)";
        SourceSubType := 0;
        SourceID := TransferLine."Document No.";
        SourceRefNo := TransferLine."Line No.";
        SourceProdOrderLineNo := 0;
    end;

    local procedure CreateSalesAsSupply(ItemNo: Code[20]; Qty: Decimal; UOMCode: Code[10]; LocationCode: Code[10]; LotNo: Code[10]; ShipmentDate: Date)
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSaleLine(SalesLine, SalesLine."Document Type"::"Return Order", ItemNo, UOMCode, Qty, LocationCode, ShipmentDate);
        RoundingIssuesCreateReservationEntry(true, true, ItemNo, 0, SalesLine."Quantity (Base)",
          DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.", 0, '',
          SalesLine."Qty. per Unit of Measure", LotNo, SalesLine."Shipment Date");
    end;

    local procedure CreateSalesAsDemand(ItemUnitOfMeasureCAS: Record "Item Unit of Measure"; Qty: Decimal; LocationCode: Code[10]; LotNo: Code[10]; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal; var SourceSubType: Option; var SourceID: Code[20]; var SourceRefNo: Integer; var SourceProdOrderLineNo: Integer; ShipmentDate: Date)
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSaleLine(SalesLine, SalesLine."Document Type"::Order, ItemUnitOfMeasureCAS."Item No.",
          ItemUnitOfMeasureCAS.Code, Qty, LocationCode, ShipmentDate);
        RoundingIssuesCreateReservationEntry(false, true, SalesLine."No.", -SalesLine.Quantity, -SalesLine."Quantity (Base)",
          DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.", 0, '',
          SalesLine."Qty. per Unit of Measure", LotNo, SalesLine."Shipment Date");

        QtyToReserve := SalesLine.Quantity;
        QtyToReserveBase := SalesLine."Quantity (Base)";
        SourceSubType := SalesLine."Document Type".AsInteger();
        SourceID := SalesLine."Document No.";
        SourceRefNo := SalesLine."Line No.";
        SourceProdOrderLineNo := 0;
    end;

    local procedure CreateServiceAsDemand(ItemUnitOfMeasureCAS: Record "Item Unit of Measure"; Qty: Decimal; LocationCode: Code[10]; LotNo: Code[10]; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal; var SourceSubType: Option; var SourceID: Code[20]; var SourceRefNo: Integer; var SourceProdOrderLineNo: Integer; NeedByDate: Date)
    var
        ServiceLine: Record "Service Line";
    begin
        CreateServiceLine(ServiceLine, ItemUnitOfMeasureCAS."Item No.", ItemUnitOfMeasureCAS.Code, Qty, LocationCode, NeedByDate);
        RoundingIssuesCreateReservationEntry(false, true, ServiceLine."No.", -ServiceLine.Quantity, -ServiceLine."Quantity (Base)",
          DATABASE::"Service Line", ServiceLine."Document Type".AsInteger(), ServiceLine."Document No.", ServiceLine."Line No.", 0, '',
          ServiceLine."Qty. per Unit of Measure", LotNo, ServiceLine."Needed by Date");

        QtyToReserve := ServiceLine.Quantity;
        QtyToReserveBase := ServiceLine."Quantity (Base)";
        SourceSubType := ServiceLine."Document Type".AsInteger();
        SourceID := ServiceLine."Document No.";
        SourceRefNo := ServiceLine."Line No.";
        SourceProdOrderLineNo := 0;
    end;

    local procedure CreateItemAndUpdateInventory(var Item: Record Item; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItem(Item);
        CreateItemJournalLine(ItemJournalLine, Item."No.", Quantity, ItemJournalLine."Entry Type"::Purchase);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; Quantity: Decimal; EntryType: Enum "Item Ledger Document Type")
    begin
        // Create Item Journal to populate Item Quantity.
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, EntryType, ItemNo, Quantity);
        ItemJournalLine.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));
        ItemJournalLine.Validate("Unit Amount", ItemJournalLine."Unit Cost");
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
    end;

    local procedure CreateProductionOrderFromSalesOrder(SalesHeader: Record "Sales Header")
    var
        ProductionOrder: Record "Production Order";
    begin
        LibraryVariableStorage.Enqueue(ProdOrderCreatedMsg); // Enqueue variable for created Production Order message in MessageHandler.
        LibraryManufacturing.CreateProductionOrderFromSalesOrder(
            SalesHeader, ProductionOrder.Status::Released, "Create Production Order Type"::ItemOrder);
    end;

    local procedure CreateItemUOMAndUpdateItem(var Item: Record Item; var QtyPerUnitOfMeasure: Decimal)
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", LibraryRandom.RandDec(10, 2));
        Item.Validate("Sales Unit of Measure", ItemUnitOfMeasure.Code);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Modify(true);
        QtyPerUnitOfMeasure := ItemUnitOfMeasure."Qty. per Unit of Measure";
    end;

    local procedure ReservationFromSalesOrder(No: Code[20])
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenView();
        SalesOrder.FILTER.SetFilter("No.", No);
        SalesOrder.SalesLines.Reserve.Invoke();
        SalesOrder.Close();
    end;

    local procedure ReservationFromProductionOrderComponents(ItemNo: Code[20])
    var
        ProdOrderComponents: TestPage "Prod. Order Components";
    begin
        ProdOrderComponents.OpenView();
        ProdOrderComponents.FILTER.SetFilter("Item No.", ItemNo);
        ProdOrderComponents.Reserve.Invoke();
        ProdOrderComponents.Close();
    end;

    local procedure ReservationFromAssemblyOrder(No: Code[20])
    var
        AssemblyOrder: TestPage "Assembly Order";
    begin
        AssemblyOrder.OpenView();
        AssemblyOrder.FILTER.SetFilter("No.", No);
        AssemblyOrder.Lines."Reserve Item".Invoke();
        AssemblyOrder.Close();
    end;

    local procedure SelectSalesLineQty(DocumentNo: Code[20]): Decimal
    var
        SalesLine: Record "Sales Line";
    begin
        SelectSalesLine(SalesLine, DocumentNo);
        exit(SalesLine.Quantity);
    end;

    local procedure SelectSalesLine(var SalesLine: Record "Sales Line"; DocumentNo: Code[20])
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.FindFirst();
    end;

    local procedure CreateAndPostPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Quantity: Decimal; Invoice: Boolean)
    begin
        CreatePurchaseOrder(PurchaseHeader, ItemNo, Quantity);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, Invoice);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', ItemNo, Quantity, '', 0D);
    end;

    local procedure UpdatePurchLineQtyToReceive(DocumentNo: Code[20]; QtyToReceive: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.FindFirst();
        PurchaseLine.Validate("Qty. to Receive", QtyToReceive);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateItemsSetup(var Item: Record Item): Code[20]
    var
        ProductionBOMHeader: Record "Production BOM Header";
        Item2: Record Item;
    begin
        // Create Child Items.
        CreateItemAndUpdateInventory(Item2, LibraryRandom.RandDec(100, 2));

        // Create Production BOM, Parent item and Attach Production BOM.
        CreateCertifiedProdBOM(ProductionBOMHeader, Item2);
        CreateProdItem(Item, ProductionBOMHeader."No.");
        exit(Item2."No.");
    end;

    local procedure CreateCertifiedProdBOM(var ProductionBOMHeader: Record "Production BOM Header"; Item: Record Item)
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        // Create Production BOM.
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item."No.", 1);  // Value important.
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure CreateProdItem(var Item: Record Item; ProductionBOMNo: Code[20])
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Manufacturing Policy", Item."Manufacturing Policy"::"Make-to-Order");
        Item.Validate("Production BOM No.", ProductionBOMNo);
        Item.Modify(true);
    end;

    local procedure SelectItemInventory(ItemNo: Code[20]): Decimal
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        Item.CalcFields(Inventory);
        exit(Item.Inventory);
    end;

    local procedure CreateAndRefreshProdOrder(var ProductionOrder: Record "Production Order"; Status: Enum "Production Order Status"; SourceNo: Code[20]; Quantity: Decimal)
    begin
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, Status, ProductionOrder."Source Type"::Item, SourceNo, Quantity);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure DeleteProductionOrder(Status: Enum "Production Order Status"; SourceNo: Code[20])
    var
        ProductionOrder: Record "Production Order";
    begin
        ProductionOrder.SetRange(Status, Status);
        ProductionOrder.SetRange("Source No.", SourceNo);
        ProductionOrder.FindFirst();
        ProductionOrder.Delete(true);
    end;

    local procedure CreateOutputJournal(ProductionOrderNo: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.ClearItemJournal(OutputItemJournalTemplate, OutputItemJournalBatch);
        LibraryManufacturing.CreateOutputJournal(ItemJournalLine, OutputItemJournalTemplate, OutputItemJournalBatch, '', ProductionOrderNo);
        LibraryManufacturing.OutputJnlExplodeRoute(ItemJournalLine);
    end;

    local procedure SelectOutputJournalLine(var ItemJournalLine: Record "Item Journal Line"; ProductionOrderNo: Code[20])
    begin
        ItemJournalLine.SetRange("Order No.", ProductionOrderNo);
        ItemJournalLine.FindFirst();
    end;

    local procedure FindReservationEntry(var ReservationEntry: Record "Reservation Entry"; ItemNo: Code[20]; ReservationStatus: Enum "Reservation Status"; SourceType: Integer)
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.SetRange("Reservation Status", ReservationStatus);
        ReservationEntry.SetRange("Source Type", SourceType);
        ReservationEntry.FindFirst();
    end;

    local procedure UpdateOutputJournal(var ItemJournalLine: Record "Item Journal Line"; FinishedQty: Decimal)
    begin
        ItemJournalLine.Validate("Output Quantity", FinishedQty);
        ItemJournalLine.Modify(true);
    end;

    local procedure SelectItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemNo: Code[20])
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindFirst();
    end;

    local procedure UpdateSalesLineApplyToEntry(DocumentNo: Code[20]; ApplyToItemEntry: Integer)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.FindFirst();
        SalesLine.Validate("Appl.-to Item Entry", ApplyToItemEntry);
        SalesLine.Modify(true);
    end;

    local procedure SelectGLEntry(var GLEntry: Record "G/L Entry"; Item: Record Item)
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        InventoryPostingSetup.SetRange("Invt. Posting Group Code", Item."Inventory Posting Group");
        InventoryPostingSetup.FindFirst();
        SelectItemLedgerEntry(ItemLedgerEntry, Item."No.");

        GLEntry.SetRange("Document No.", ItemLedgerEntry."Document No.");
        GLEntry.SetRange("G/L Account No.", InventoryPostingSetup."Inventory Account");
        GLEntry.FindSet();
    end;

    local procedure VerifyReservationQty(Reservation: TestPage Reservation)
    begin
        Reservation."Total Quantity".AssertEquals(InitialInventory);
        Reservation."Current Reserved Quantity".AssertEquals(ExpCurrentReservedQty);
    end;

    local procedure VerifyReservQtyTwoAvailableLines(Reservation: TestPage Reservation)
    var
        ActualTotalAvailable: Decimal;
        ActualCurrentReserved: Decimal;
    begin
        // Verify values for both Production Order lines.
        // Retrieve value from Production Order lines.
        Reservation.First();
        ActualTotalAvailable := Reservation."Total Quantity".AsDecimal();
        ActualCurrentReserved := Reservation."Current Reserved Quantity".AsDecimal();
        Reservation.Next();
        ActualTotalAvailable += Reservation."Total Quantity".AsDecimal();
        ActualCurrentReserved += Reservation."Current Reserved Quantity".AsDecimal();

        // Verify Total available and reserved quantity.
        Assert.AreEqual(InitialInventory, ActualTotalAvailable, TotalQuantityErr);
        Assert.AreEqual(ExpCurrentReservedQty, ActualCurrentReserved, ReservedQuantityErr);
    end;

    local procedure VerifyZeroReservationSalesQty(DocumentNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.FindFirst();
        SalesLine.CalcFields("Reserved Quantity");
        SalesLine.TestField("Reserved Quantity", 0);
        SalesLine.TestField(Planned, false);
    end;

    local procedure VerifyQtyOnItemLedgerEntry(ItemNo: Code[20]; Quantity: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        SelectItemLedgerEntry(ItemLedgerEntry, ItemNo);
        ItemLedgerEntry.TestField(Quantity, Quantity);
    end;

    local procedure VerifyReservationQtyFinishProduction(Reservation: TestPage Reservation)
    begin
        Reservation.QtyToReserveBase.AssertEquals(InitialInventory);
        Reservation.QtyReservedBase.AssertEquals(ExpCurrentReservedQty);
    end;

    local procedure VerifySalesShipment(OrderNo: Code[20]; QtyToShip: Decimal)
    var
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        SalesShipmentLine.SetRange("Order No.", OrderNo);
        SalesShipmentLine.FindFirst();
        SalesShipmentLine.TestField(Quantity, QtyToShip);
    end;

    local procedure VerifyShipmentDate(TransactionDate: Date; SalesLine: Record "Sales Line")
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        FindReservationEntry(ReservationEntry, SalesLine."No.", ReservationEntry."Reservation Status"::Reservation, DATABASE::"Sales Line");
        Assert.AreEqual(TransactionDate, ReservationEntry."Shipment Date", ShipDateChangedErr);
        Assert.AreEqual(TransactionDate, SalesLine."Shipment Date", ShipDateChangedErr);
    end;

    local procedure VerifyGLEntry(ItemNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
        Item: Record Item;
        ExpectedAmount: Decimal;
    begin
        // Expected Amount.
        GeneralLedgerSetup.Get();
        Item.Get(ItemNo);
        ExpectedAmount := SelectItemInventory(ItemNo) * Item."Unit Cost";

        // Select GL Entry - Inventory Account.
        SelectGLEntry(GLEntry, Item);

        // Verify Amounts are equal.
        Assert.AreNearlyEqual(ExpectedAmount, GLEntry.Amount, GeneralLedgerSetup."Amount Rounding Precision", AmountsMustMatchErr);
    end;

    local procedure VerifyDatesOnReservationEntryAfterCancelReservation(SupplySourceType: Option; DemandSourceType: Option)
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ReservationEntry: Record "Reservation Entry";
        ReservationEngineMgt: Codeunit "Reservation Engine Mgt.";
        ReservationManagement: Codeunit "Reservation Management";
        LocationCode: Code[10];
        LotNo: Code[10];
        FullAutoReservation: Boolean;
        QtyToReserve: Decimal;
        QtyToReserveBase: Decimal;
        SourceSubType: Option;
        SourceID: Code[20];
        SourceRefNo: Integer;
        SourceProdOrderLineNo: Integer;
        ShipmentDate: Date;
    begin
        // Setup: Create Supply and Demand with Lot.
        Initialize();
        CreateItemWithLotSpecificTracking(Item, ItemUnitOfMeasure);
        LotNo := LibraryUtility.GenerateGUID();
        LocationCode := LibraryUtility.GenerateGUID();
        ShipmentDate := CalcDate(StrSubstNo('<%1D>', LibraryRandom.RandInt(5)), WorkDate());
        CreateSupply(SupplySourceType, ItemUnitOfMeasure, LocationCode, LotNo, WorkDate(), LibraryRandom.RandDecInRange(15, 20, 2));
        CreateDemand(DemandSourceType, ItemUnitOfMeasure, LibraryRandom.RandDec(10, 2), LocationCode, LotNo,
          QtyToReserve, QtyToReserveBase, SourceSubType, SourceID, SourceRefNo, SourceProdOrderLineNo, ShipmentDate);

        // Reserve supply against demand.
        RoundingIssuesSetDemandSource(ReservationManagement, DemandSourceType, SourceSubType, SourceID, SourceRefNo, SourceProdOrderLineNo);
        ReservationManagement.AutoReserve(FullAutoReservation, '', WorkDate(), QtyToReserve, QtyToReserveBase);
        FindReservationEntry(ReservationEntry, Item."No.", ReservationEntry."Reservation Status"::Reservation, SupplySourceType);

        // Exercise: Cancel Reservation.
        ReservationEngineMgt.CancelReservation(ReservationEntry);

        // Verify: Verify Expected Receipt,Shipment Dates on Reservation Entries and no Reservation Entries exist for ILE after Cancel Reservation.
        if SupplySourceType = DATABASE::"Item Ledger Entry" then begin
            ReservationEntry.SetRange("Item No.", Item."No.");
            ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Surplus);
            ReservationEntry.SetRange("Source Type", SupplySourceType);
            Assert.IsTrue(ReservationEntry.IsEmpty, ReservEntryMustNotExistErr)
        end else
            VerifyShipmentAndExpRcptDateOnReservationEntry(ReservationEntry, Item."No.", SupplySourceType, 0D, WorkDate());
        VerifyShipmentAndExpRcptDateOnReservationEntry(ReservationEntry, Item."No.", DemandSourceType, ShipmentDate, 0D);
    end;

    local procedure VerifyShipmentAndExpRcptDateOnReservationEntry(ReservationEntry: Record "Reservation Entry"; ItemNo: Code[20]; SourceType: Integer; ShipmentDate: Date; ExpectedReceiptDate: Date)
    begin
        FindReservationEntry(ReservationEntry, ItemNo, ReservationEntry."Reservation Status"::Surplus, SourceType);
        ReservationEntry.TestField("Shipment Date", ShipmentDate);
        ReservationEntry.TestField("Expected Receipt Date", ExpectedReceiptDate);
    end;

    local procedure VerifyQtyInReservationEntry(ItemNo: Code[20]; SourceType: Integer; Quantity: Decimal)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        FindReservationEntry(ReservationEntry, ItemNo, ReservationEntry."Reservation Status"::Reservation, SourceType);
        ReservationEntry.TestField(Quantity, Quantity);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationPageHandler(var Reservation: TestPage Reservation)
    begin
        MessageCounter := MessageCounter + 1;
        case MessageCounter of
            1:
                Reservation."Reserve from Current Line".Invoke();  // Reserve from Current Line.
            2:
                VerifyReservationQty(Reservation);  // Verify Total and Reserved Quantities.
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationPageHandler2(var Reservation: TestPage Reservation)
    begin
        Reservation."Total Quantity".DrillDown();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailableAssemblyHeadersPageHandler(var AvailableAssemblyHeaders: TestPage "Available - Assembly Headers")
    begin
        AvailableAssemblyHeaders.Reserve.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AutoReservationPageHandler(var Reservation: TestPage Reservation)
    begin
        MessageCounter := MessageCounter + 1;
        case MessageCounter of
            1:
                Reservation."Auto Reserve".Invoke();  // Auto Reserve.
            2:
                VerifyReservationQty(Reservation);  // Verify Total and Reserved Quantities.
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TwoProdOrderReservPageHandler(var Reservation: TestPage Reservation)
    begin
        MessageCounter := MessageCounter + 1;
        case MessageCounter of
            1:
                begin
                    Reservation.First();
                    Reservation."Reserve from Current Line".Invoke();  // Reserve from Current Line for first Production Order.
                    Reservation.Next();
                    Reservation."Reserve from Current Line".Invoke();  // Reserve from Current Line for second Production Order.
                end;
            2:
                VerifyReservQtyTwoAvailableLines(Reservation);  // Verify Total and Reserved Quantities.
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TwoProdAutoReservPageHandler(var Reservation: TestPage Reservation)
    begin
        MessageCounter := MessageCounter + 1;
        case MessageCounter of
            1:
                Reservation."Auto Reserve".Invoke();  // Auto Reserve.
            2:
                VerifyReservQtyTwoAvailableLines(Reservation);  // Verify Total and Reserved Quantities.
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationCancelPageHandler(var Reservation: TestPage Reservation)
    begin
        MessageCounter := MessageCounter + 1;
        case MessageCounter of
            1:
                Reservation."Reserve from Current Line".Invoke();  // Reserve from Current Line.
            2:
                Reservation.CancelReservationCurrentLine.Invoke();  // Cancel Reservation.
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AutoReserveCancelPageHandler(var Reservation: TestPage Reservation)
    begin
        MessageCounter := MessageCounter + 1;
        case MessageCounter of
            1:
                Reservation."Auto Reserve".Invoke();  // Auto Reserve.
            2:
                Reservation.CancelReservationCurrentLine.Invoke();  // Cancel Reservation.
        end;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure CancelReserveConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(CancelReservationTxt, Question);
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationOutputPartialPageHandler(var Reservation: TestPage Reservation)
    begin
        MessageCounter := MessageCounter + 1;
        case MessageCounter of
            1:
                Reservation."Reserve from Current Line".Invoke();  // Reserve from Current Line.
            2:
                VerifyReservQtyTwoAvailableLines(Reservation);  // Verify Total and Reserved Quantities.
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationFinishProductionPageHandler(var Reservation: TestPage Reservation)
    begin
        MessageCounter := MessageCounter + 1;
        case MessageCounter of
            1:
                Reservation."Reserve from Current Line".Invoke();  // Reserve from Current Line.
            2:
                VerifyReservationQtyFinishProduction(Reservation);  // Verify Quantity To Reserve and Quantity Reserved as per finished Production Order.
        end;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure MissingOutputConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Question);
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage); // Dequeue variable.
        Assert.ExpectedMessage(ExpectedMessage, Message);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure StatisticsMessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(ValueEntriesWerePostedTxt, Message);
    end;

    [RecallNotificationHandler]
    [Scope('OnPrem')]
    procedure RecallNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendAvailabilityNotificationHandler(var Notification: Notification): Boolean
    var
        Item: Record Item;
        ItemCheckAvail: Codeunit "Item-Check Avail.";
        AvailableToPromise: Codeunit "Available to Promise";
    begin
        Item.Get(ItemNo);
        Assert.AreEqual(Item."No.", Notification.GetData('ItemNo'), 'Item No. was different than expected');
        Assert.AreEqual(Format(AvailableToPromise.CalcAvailableInventory(Item)), Notification.GetData('InventoryQty'),
          'Available Inventory was different than expected');
        ItemCheckAvail.ShowNotificationDetails(Notification);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure NotificationDetailsHandler(var ItemAvailabilityCheck: TestPage "Item Availability Check")
    var
        Item: Record Item;
        AvailableToPromise: Codeunit "Available to Promise";
    begin
        Item.Get(ItemNo);
        ItemAvailabilityCheck.AvailabilityCheckDetails."No.".AssertEquals(Item."No.");
        ItemAvailabilityCheck.AvailabilityCheckDetails.Description.AssertEquals(Item.Description);
        ItemAvailabilityCheck.InventoryQty.AssertEquals(AvailableToPromise.CalcAvailableInventory(Item));
    end;
}

