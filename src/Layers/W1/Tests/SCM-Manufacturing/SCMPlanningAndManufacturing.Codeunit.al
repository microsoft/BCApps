// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Test;

using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Location;
using Microsoft.Service.Test;
using System.TestLibraries.Utilities;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.Inventory.Requisition;
using Microsoft.Sales.Document;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Journal;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Inventory.Planning;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.Forecast;
using Microsoft.Warehouse.Structure;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Inventory.BOM;
using Microsoft.Assembly.Document;
using Microsoft.Purchases.Setup;
using Microsoft.Sales.Setup;
using Microsoft.Foundation.Calendar;
using System.Utilities;
using Microsoft.Inventory.Ledger;
using Microsoft.Warehouse.Setup;
using Microsoft.Foundation.Navigate;
using Microsoft.Inventory.Setup;

codeunit 137080 "SCM Planning And Manufacturing"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SCM]
        isInitialized := false;
    end;

    var
        OutputItemJournalTemplate: Record "Item Journal Template";
        OutputItemJournalBatch: Record "Item Journal Batch";
        LocationBlue: Record Location;
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        isInitialized: Boolean;
        NoActionMessagesExistErr: Label 'No action messages exist.';
        ChangeWillNotAffectMsg: Label 'The change will not affect existing entries';
        IllegalActionMessageRelationErr: Label 'Illegal Action Message relation.';
        YouWantToContinueConfirmQst: Label 'Are you sure that you want to continue?';
        PostJournalLinesConfirmQst: Label 'Do you want to post the journal lines?';
        JournalLinesSuccessfullyPostedMsg: Label 'The journal lines were successfully posted.';
        ReservationEntryMustBeEmptyErr: Label 'Reservation Entry must be empty.';
        ConfirmDeleteItemTrackingQst: Label 'Item tracking is defined for item';
        DueDateErr: Label 'Requisition Line Due Date for proposed Production Order can''t be later than demand Sales Order.';
        StatusMustBeCertifiedErr: Label 'Routing Header No. %1 is not certified.', Comment = '%1 - Routing No.';
        ProdBOMMustBeCertifiedErr: Label 'Status must be equal to ''Certified''';
        ErrorsWhenPlanningMsg: Label 'Not all items were planned.';
        OnlyOneRecordErr: Label 'Only one record is expected.';
        BinCodesNotEqualErr: Label 'Bin Codes are not equal.';

    [Test]
    [Scope('OnPrem')]
    procedure ForwardPlanningOnPurchaseOrder()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        PlannedReceiptDate: Date;
        ExpectedReceiptDate: Date;
    begin
        // Setup: Create Initial Setup for Planning.
        Initialize();
        CreateInitialSetupForPlanning(LocationBlue, Vendor, Item, '');  // Use Blank for Base Calendar.

        // Exercise.
        CreatePurchaseOrder(PurchaseLine, Vendor."No.", Item."No.", LocationBlue.Code, 0D);  // Use 0D for Expected Receipt Date.

        // Verify.
        PlannedReceiptDate := CalcDate(Vendor."Lead Time Calculation", WorkDate());  // Value required for test.
        ExpectedReceiptDate :=
          CalcDate('<' + GetDefaultSafetyLeadTime() + '>', CalcDate(LocationBlue."Inbound Whse. Handling Time", PlannedReceiptDate));  // Value required for test.
        VerifyPlanningDatesOnPurchaseLine(PurchaseLine, WorkDate(), PlannedReceiptDate, ExpectedReceiptDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ForwardPlanningOnPurchaseOrderUsingBaseCalendar()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        Location: Record Location;
        PlannedReceiptDate: Date;
        ExpectedReceiptDate: Date;
    begin
        // Setup: Create Initial Setup for Planning with Base Calendar.
        Initialize();
        LibraryWarehouse.CreateLocation(Location);
        CreateInitialSetupForPlanningWithBaseCalendar(Location, Vendor, Item);

        // Exercise.
        CreatePurchaseOrder(PurchaseLine, Vendor."No.", Item."No.", Location.Code, 0D);  // Use 0D for Expected Receipt Date.

        // Verify.
        PlannedReceiptDate := CalculateDateWithNonWorkingDays(WorkDate() + 1, CalcDate(Vendor."Lead Time Calculation", WorkDate()), 1);  // Use 1 for Forward Planning.
        ExpectedReceiptDate :=
          CalculateDateWithNonWorkingDays(
            PlannedReceiptDate,
            CalcDate('<' + GetDefaultSafetyLeadTime() + '>', CalcDate(Location."Inbound Whse. Handling Time", PlannedReceiptDate)), 1);  // Use 1 for Forward Planning.
        VerifyPlanningDatesOnPurchaseLine(PurchaseLine, WorkDate(), PlannedReceiptDate, ExpectedReceiptDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ForwardPlanningOnRequisitionLine()
    var
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        Item: Record Item;
        ExpectedReceiptDate: Date;
        PlannedReceiptDate: Date;
    begin
        // Setup: Create Initial Setup for Planning.
        Initialize();
        CreateInitialSetupForPlanning(LocationBlue, Vendor, Item, '');  // Use Blank for Base Calendar.

        // Exercise.
        CarryOutRequisitionLine(PurchaseLine, Item."No.", LocationBlue.Code, 0D);  // Use 0D for Expected Receipt Date.

        // Verify.
        PlannedReceiptDate := CalcDate(Vendor."Lead Time Calculation", WorkDate());  // Value required for test.
        ExpectedReceiptDate :=
          CalcDate('<' + GetDefaultSafetyLeadTime() + '>', CalcDate(LocationBlue."Inbound Whse. Handling Time", PlannedReceiptDate));  // Value required for test.
        VerifyPlanningDatesOnPurchaseLine(PurchaseLine, WorkDate(), PlannedReceiptDate, ExpectedReceiptDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ForwardPlanningOnRequisitionLineUsingBaseCalendar()
    var
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        Item: Record Item;
        Location: Record Location;
        ExpectedReceiptDate: Date;
        PlannedReceiptDate: Date;
    begin
        // Setup: Create Initial Setup for Planning with Base Calendar.
        Initialize();
        LibraryWarehouse.CreateLocation(Location);
        CreateInitialSetupForPlanningWithBaseCalendar(Location, Vendor, Item);

        // Exercise.
        CarryOutRequisitionLine(PurchaseLine, Item."No.", Location.Code, 0D);  // Use 0D for Expected Receipt Date.

        // Verify.
        PlannedReceiptDate := CalculateDateWithNonWorkingDays(WorkDate() + 1, CalcDate(Vendor."Lead Time Calculation", WorkDate()), 1);  // Use 1 for Forward Planning.
        ExpectedReceiptDate :=
          CalculateDateWithNonWorkingDays(
            PlannedReceiptDate,
            CalcDate('<' + GetDefaultSafetyLeadTime() + '>', CalcDate(Location."Inbound Whse. Handling Time", PlannedReceiptDate)), 1);  // Use 1 for Forward Planning.
        VerifyPlanningDatesOnPurchaseLine(PurchaseLine, WorkDate(), PlannedReceiptDate, ExpectedReceiptDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BackwardPlanningOnPurchaseOrder()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        PlannedReceiptDate: Date;
        OrderDate: Date;
    begin
        // Setup: Create Initial Setup for Planning.
        Initialize();
        CreateInitialSetupForPlanning(LocationBlue, Vendor, Item, '');  // Use Blank for Base Calendar.

        // Exercise.
        CreatePurchaseOrder(PurchaseLine, Vendor."No.", Item."No.", LocationBlue.Code, WorkDate());

        // Verify.
        PlannedReceiptDate :=
          CalcDate(
            '<-' + GetDefaultSafetyLeadTime() + '>', CalcDate('<-' + Format(LocationBlue."Inbound Whse. Handling Time") + '>', WorkDate()));  // Value required for test.
        OrderDate := CalcDate('<-' + Format(Vendor."Lead Time Calculation") + '>', PlannedReceiptDate);  // Value required for test.
        VerifyPlanningDatesOnPurchaseLine(PurchaseLine, OrderDate, PlannedReceiptDate, WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BackwardPlanningOnPurchaseOrderUsingBaseCalendar()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        Location: Record Location;
        PlannedReceiptDate: Date;
        OrderDate: Date;
        ExpectedReceiptDate: Date;
    begin
        // Setup: Create Initial Setup for Planning with Base Calendar.
        Initialize();
        LibraryWarehouse.CreateLocation(Location);
        CreateInitialSetupForPlanningWithBaseCalendar(Location, Vendor, Item);

        // Exercise.
        CreatePurchaseOrder(PurchaseLine, Vendor."No.", Item."No.", Location.Code, WorkDate());

        // Verify.
        PlannedReceiptDate :=
          CalculateDateWithNonWorkingDays(
            CalcDate(
              '<-' + GetDefaultSafetyLeadTime() + '>', CalcDate('<-' + Format(Location."Inbound Whse. Handling Time") + '>', WorkDate())),
            WorkDate() - 1, -1);  // Use -1 for Backward Planning.
        OrderDate :=
          CalculateDateWithNonWorkingDays(
            CalcDate('<-' + Format(Vendor."Lead Time Calculation") + '>', PlannedReceiptDate), PlannedReceiptDate, -1);  // Use -1 for Backward Planning.
        ExpectedReceiptDate := CalculateDateWithNonWorkingDays(WorkDate(), WorkDate(), 1);
        VerifyPlanningDatesOnPurchaseLine(PurchaseLine, OrderDate, PlannedReceiptDate, ExpectedReceiptDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BackwardPlanningOnRequisitionLine()
    var
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        Item: Record Item;
        OrderDate: Date;
        PlannedReceiptDate: Date;
    begin
        // Setup: Create Initial Setup for Planning.
        Initialize();
        CreateInitialSetupForPlanning(LocationBlue, Vendor, Item, '');  // Use Blank for Base Calendar.

        // Exercise.
        CarryOutRequisitionLine(PurchaseLine, Item."No.", LocationBlue.Code, WorkDate());

        // Verify.
        PlannedReceiptDate :=
          CalcDate(
            '<-' + GetDefaultSafetyLeadTime() + '>', CalcDate('<-' + Format(LocationBlue."Inbound Whse. Handling Time") + '>', WorkDate()));  // Value required for test.
        OrderDate := CalcDate('<-' + Format(Vendor."Lead Time Calculation") + '>', PlannedReceiptDate);  // Value required for test.
        VerifyPlanningDatesOnPurchaseLine(PurchaseLine, OrderDate, PlannedReceiptDate, WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BackwardPlanningOnRequisitionLineUsingBaseCalendar()
    var
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        Item: Record Item;
        Location: Record Location;
        OrderDate: Date;
        PlannedReceiptDate: Date;
        ExpectedReceiptDate: Date;
    begin
        // Setup: Create Initial Setup for Planning with Base Calendar.
        Initialize();
        LibraryWarehouse.CreateLocation(Location);
        CreateInitialSetupForPlanningWithBaseCalendar(Location, Vendor, Item);

        // Exercise.
        CarryOutRequisitionLine(PurchaseLine, Item."No.", Location.Code, WorkDate());

        // Verify.
        PlannedReceiptDate :=
          CalculateDateWithNonWorkingDays(
            CalcDate(
              '<-' + GetDefaultSafetyLeadTime() + '>', CalcDate('<-' + Format(Location."Inbound Whse. Handling Time") + '>', WorkDate())),
            WorkDate() - 1, -1);  // Use -1 for Backward Planning.
        OrderDate :=
          CalculateDateWithNonWorkingDays(
            CalcDate('<-' + Format(Vendor."Lead Time Calculation") + '>', PlannedReceiptDate), PlannedReceiptDate, -1);  // Use -1 for Backward Planning.
        ExpectedReceiptDate := CalculateDateWithNonWorkingDays(WorkDate(), WorkDate(), 1);
        VerifyPlanningDatesOnPurchaseLine(PurchaseLine, OrderDate, PlannedReceiptDate, ExpectedReceiptDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorNoActionMessagesExistOnGetActionMessages()
    var
        Item: Record Item;
    begin
        // Setup: Create Item.
        Initialize();
        LibraryInventory.CreateItem(Item);

        // Exercise.
        asserterror LibraryPlanning.GetActionMessages(Item);

        // Verify.
        Assert.ExpectedError(NoActionMessagesExistErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CalcRegenPlanWithPurchaseReplenishmentSystem()
    begin
        // Setup.
        Initialize();
        GetActionMessagesWithPurchaseReplenishmentSystem(false, false);  // Use BeforeIllegalActionMessage and AfterIllegalActionMessage as False.
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ErrorIllegalMessageRelationOnGetActionMessages()
    begin
        // Setup.
        Initialize();
        GetActionMessagesWithPurchaseReplenishmentSystem(true, false);  // Use BeforeIllegalActionMessage as True and AfterIllegalActionMessage as False.
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure GetActionMessagesAfterIllegalActionMessage()
    begin
        // Setup.
        Initialize();
        GetActionMessagesWithPurchaseReplenishmentSystem(true, true);  // Use BeforeIllegalActionMessage and AfterIllegalActionMessage as True.
    end;

    local procedure GetActionMessagesWithPurchaseReplenishmentSystem(BeforeIllegalActionMessage: Boolean; AfterIllegalActionMessage: Boolean)
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        SalesLine: Record "Sales Line";
    begin
        // Create Sales Order with New Item having Purchase Replenishment System and Make-to-Order Manufacturing Policy.
        CreateItem(Item, Item."Replenishment System"::Purchase, Item."Manufacturing Policy"::"Make-to-Order");
        CreateSalesOrder(SalesLine, Item."No.", LocationBlue.Code);

        // Exercise.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());

        // Verify.
        VerifyRequisitionLine(SalesLine, RequisitionLine."Action Message"::New, false, RequisitionLine."Ref. Order Type"::Purchase);  // Use AcceptActionMessage as False.

        if BeforeIllegalActionMessage then begin
            // Exercise.
            UpdateQuantityOnSalesLine(SalesLine);
            DeleteRequisitionLine(Item."No.");
            asserterror LibraryPlanning.GetActionMessages(Item);

            // Verify.
            Assert.ExpectedError(IllegalActionMessageRelationErr);
        end;

        if AfterIllegalActionMessage then begin
            // Exercise.
            DeleteRequisitionLine(Item."No.");
            UpdateQuantityOnSalesLine(SalesLine);
            LibraryPlanning.GetActionMessages(Item);

            // Verify.
            VerifyRequisitionLine(SalesLine, RequisitionLine."Action Message"::New, true, RequisitionLine."Ref. Order Type"::Purchase);  // Use AcceptActionMessage as True.
        end;
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CalcRegenPlanWithProdOrderReplenishmentSystem()
    begin
        // Setup.
        Initialize();
        GetActionMessagesWithProdOrderReplenishmentSystem(false, false);  // Use CarryOutActionMessage and UpdateQuantity as False.
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CarryOutActionMsgWithProdOrderReplenishmentSystem()
    begin
        // Setup.
        Initialize();
        GetActionMessagesWithProdOrderReplenishmentSystem(true, false);  // Use CarryOutActionMessage as True and UpdateQuantity as False.
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure GetActionMessagesWithUpdatedQuantity()
    begin
        // Setup.
        Initialize();
        GetActionMessagesWithProdOrderReplenishmentSystem(true, true);  // Use CarryOutActionMessage and UpdateQuantity as True.
    end;

    local procedure GetActionMessagesWithProdOrderReplenishmentSystem(CarryOutActionMessage: Boolean; UpdateQuantity: Boolean)
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        SalesLine: Record "Sales Line";
        OldPlanningWarning: Boolean;
    begin
        // Update Planning Warning on Manufacturing Setup. Create Sales Order with New Item having Production Order Replenishment System and Make-to-Stock Manufacturing Policy.
        UpdatePlanningWarningOnManufacturingSetup(OldPlanningWarning, false);
        CreateItem(Item, Item."Replenishment System"::"Prod. Order", Item."Manufacturing Policy"::"Make-to-Stock");
        CreateSalesOrder(SalesLine, Item."No.", LocationBlue.Code);

        // Exercise.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());

        // Verify.
        VerifyRequisitionLine(SalesLine, RequisitionLine."Action Message"::New, false, RequisitionLine."Ref. Order Type"::"Prod. Order");  // Use AcceptActionMessage as False.

        if CarryOutActionMessage then begin
            // Exercise.
            CarryOutActionMessageOnPlanningWorksheet(Item."No.");

            // Verify.
            VerifyProductionOrder(SalesLine);
        end;

        if UpdateQuantity then begin
            // Exercise.
            UpdateQuantityOnSalesLine(SalesLine);
            LibraryPlanning.GetActionMessages(Item);

            // Verify.
            VerifyRequisitionLine(
              SalesLine, RequisitionLine."Action Message"::"Change Qty.", true, RequisitionLine."Ref. Order Type"::"Prod. Order");  // Use AcceptActionMessage as True.
        end;

        // Tear down.
        UpdatePlanningWarningOnManufacturingSetup(OldPlanningWarning, OldPlanningWarning);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OutputJournalAfterExplodeRouting()
    begin
        // Setup.
        Initialize();
        FinishedRoutingStatusAfterPostOutputJournal(false, false, false);  // Use PostOutputJournal, Finished and UpdateRoutingStatus as False.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostUnfinishedOutputAfterDeleteOutputJournalLine()
    begin
        // Setup.
        Initialize();
        FinishedRoutingStatusAfterPostOutputJournal(true, false, false);  // Use PostOutputJournal as True. Use Finished and UpdateRoutingStatus as False.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostFinishedOutputAfterDeleteOutputJournalLine()
    begin
        // Setup.
        Initialize();
        FinishedRoutingStatusAfterPostOutputJournal(true, true, false);  // Use PostOutputJournal and Finished as True. Use UpdateRoutingStatus as False.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure FinishedRoutingStatusAfterPostUnfinishedOutput()
    begin
        // Setup.
        Initialize();
        FinishedRoutingStatusAfterPostOutputJournal(true, false, true);  // Use PostOutputJournal and UpdateRoutingStatus as True. Use Finished as False.
    end;

    local procedure FinishedRoutingStatusAfterPostOutputJournal(PostOutputJournal: Boolean; Finished: Boolean; UpdateRoutingStatus: Boolean)
    var
        Item: Record Item;
        RoutingLine: Record "Routing Line";
        RoutingLine2: Record "Routing Line";
        ProductionOrder: Record "Production Order";
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
    begin
        // Create Item with Routing. Create and refresh Released Production Order.
        CreateItemWithRouting(Item, RoutingLine, RoutingLine2, '', true);  // Use Blank for Item Tracking Code and True for with Machine Center.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.");

        // Exercise.
        ExplodeRoutingOnOutputJournal(ProductionOrder."No.", false);

        // Verify.
        VerifyOutputJournalLine(ProductionOrder, RoutingLine);
        VerifyOutputJournalLine(ProductionOrder, RoutingLine2);

        if PostOutputJournal then begin
            // Exercise.
            PostOutputJournalAfterDeleteOutputJournalLine(ProductionOrder, RoutingLine, RoutingLine2, Finished);

            // Verify.
            if Finished then begin
                VerifyProductionOrderCapacityNeed(RoutingLine, ProductionOrder."No.", ProdOrderCapacityNeed."Time Type"::"Run Time", 0);  // Use 0 for Allocated Time.
                VerifyProductionOrderCapacityNeed(RoutingLine, ProductionOrder."No.", ProdOrderCapacityNeed."Time Type"::"Setup Time", 0);  // Use 0 for Allocated Time.
                VerifyProductionOrderCapacityNeed(
                  RoutingLine2, ProductionOrder."No.", ProdOrderCapacityNeed."Time Type"::"Run Time",
                  RoutingLine2."Run Time" * ProductionOrder.Quantity);  // Value required for Allocated Time.
                VerifyProductionOrderCapacityNeed(
                  RoutingLine2, ProductionOrder."No.", ProdOrderCapacityNeed."Time Type"::"Setup Time", RoutingLine2."Setup Time");
            end else begin
                VerifyProductionOrderCapacityNeed(
                  RoutingLine, ProductionOrder."No.", ProdOrderCapacityNeed."Time Type"::"Run Time",
                  RoutingLine."Run Time" * ProductionOrder.Quantity);  // Value required for Allocated Time.
                VerifyProductionOrderCapacityNeed(
                  RoutingLine, ProductionOrder."No.", ProdOrderCapacityNeed."Time Type"::"Setup Time", RoutingLine."Setup Time");
                VerifyProductionOrderCapacityNeed(
                  RoutingLine2, ProductionOrder."No.", ProdOrderCapacityNeed."Time Type"::"Run Time",
                  RoutingLine2."Run Time" * ProductionOrder.Quantity);  // Value required for Allocated Time.
                VerifyProductionOrderCapacityNeed(
                  RoutingLine2, ProductionOrder."No.", ProdOrderCapacityNeed."Time Type"::"Setup Time", RoutingLine2."Setup Time");
            end;
        end;

        if UpdateRoutingStatus then begin
            // Exercise.
            UpdateFinishedRoutingStatusOnProdOrderRoutingLine(ProductionOrder."No.", RoutingLine."Operation No.");

            // Verify.
            VerifyProductionOrderCapacityNeed(RoutingLine, ProductionOrder."No.", ProdOrderCapacityNeed."Time Type"::"Run Time", 0);  // Use 0 for Allocated Time.
            VerifyProductionOrderCapacityNeed(RoutingLine, ProductionOrder."No.", ProdOrderCapacityNeed."Time Type"::"Setup Time", 0);  // Use 0 for Allocated Time.
            VerifyProductionOrderCapacityNeed(
              RoutingLine2, ProductionOrder."No.", ProdOrderCapacityNeed."Time Type"::"Run Time",
              RoutingLine2."Run Time" * ProductionOrder.Quantity);  // Value required for Allocated Time.
            VerifyProductionOrderCapacityNeed(
              RoutingLine2, ProductionOrder."No.", ProdOrderCapacityNeed."Time Type"::"Setup Time", RoutingLine2."Setup Time");
        end;
    end;

    [Test]
    [HandlerFunctions('ProductionJournalPageHandler,ItemTrackingLinesPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostProductionJournalUsingLotItemTracking()
    var
        Item: Record Item;
        RoutingLine: Record "Routing Line";
        RoutingLine2: Record "Routing Line";
        ProductionOrder: Record "Production Order";
        LotNo: Code[50];
    begin
        // Setup: Create Item with Routing.
        Initialize();
        CreateItemWithRouting(Item, RoutingLine, RoutingLine2, CreateLotItemTrackingCode(), true);  // Use True for with Machine Center.

        // Exercise.
        LotNo := PostProductionJournalFromRPOWithLot(ProductionOrder, Item."No.");

        // Verify.
        VerifyItemLedgerEntry(ProductionOrder, LotNo);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure OutputJournalForMultipleExplodeRoutingUsingLot()
    begin
        // Setup.
        Initialize();
        PostOutputJournalUsingLotForMultipleExplodeRouting(false);  // Use False for Post Output.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PostOutputJournalForMultipleExplodeRoutingUsingLot()
    begin
        // Setup.
        Initialize();
        PostOutputJournalUsingLotForMultipleExplodeRouting(true);  // Use True for Post Output.
    end;

    local procedure PostOutputJournalUsingLotForMultipleExplodeRouting(PostOutput: Boolean)
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ProductionOrder: Record "Production Order";
        LotNo: Code[50];
        LotNo2: Code[50];
    begin
        // Create Lot Item with Production BOM. Create and refresh Released Production Order. Add Lot Item Tracking to Output Journal Line after Explode Routing.
        CreateLotItemWithProductionBOM(Item);
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.");
        ExplodeRoutingOnOutputJournal(ProductionOrder."No.", true);
        LotNo := AddLotItemTrackingToOutputJournalLine(ItemJournalLine, ProductionOrder);

        // Exercise.
        ExplodeRoutingOnOutputJournal(ProductionOrder."No.", true);
        LotNo2 := AddLotItemTrackingToOutputJournalLine(ItemJournalLine, ProductionOrder);

        // Verify.
        VerifyReservationEntry(ProductionOrder, LotNo2);
        VerifyEmptyReservationEntry(Item."No.", LotNo);

        if PostOutput then begin
            // Exercise.
            LibraryInventory.PostItemJournalLine(OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);

            // Verify.
            VerifyEmptyReservationEntry(Item."No.", LotNo2);
            VerifyEmptyReservationEntry(Item."No.", LotNo);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProductionOrderCapacityNeedWithoutWaitTime()
    begin
        // Setup.
        Initialize();
        ProdOrderCapacityNeedAfterRefreshReleasedProdOrder(false);  // Use False for without Wait Time.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProductionOrderCapacityNeedWithWaitTime()
    begin
        // Setup.
        Initialize();
        ProdOrderCapacityNeedAfterRefreshReleasedProdOrder(true);  // Use True for with Wait Time.
    end;

    local procedure ProdOrderCapacityNeedAfterRefreshReleasedProdOrder(WithWaitTime: Boolean)
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        RoutingLine: Record "Routing Line";
        RoutingLine2: Record "Routing Line";
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
    begin
        // Create Item with Routing.
        CreateItemWithRouting(Item, RoutingLine, RoutingLine2, '', false);  // Use Blank for Item Tracking Code and False for without Machine Center.

        // Exercise.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.");

        // Verify.
#pragma warning disable AA0181  // Find() can be used without a loop
        ProductionOrder.Find();
#pragma warning restore
        VerifyProdOrderCapacityNeedWithStartingTime(
          RoutingLine, ProductionOrder."No.", ProdOrderCapacityNeed."Send-Ahead Type"::Input, ProdOrderCapacityNeed."Time Type"::"Run Time",
          ProductionOrder."Starting Time", RoutingLine."Run Time" * ProductionOrder.Quantity);  // Value required for Allocated Time.
        VerifyProdOrderCapacityNeedWithStartingTime(
          RoutingLine2, ProductionOrder."No.", ProdOrderCapacityNeed."Send-Ahead Type"::Input, ProdOrderCapacityNeed."Time Type"::"Run Time",
          ProductionOrder."Starting Time" + RoutingLine."Run Time" * ProductionOrder.Quantity * 60000,
          RoutingLine2."Run Time" * ProductionOrder.Quantity);  // Value required for Starting Time and Allocated Time.

        if WithWaitTime then begin
            // Exercise.
            UpdateWaitTimeOnProdOrderRoutingLine(ProductionOrder."No.", RoutingLine."Operation No.");

            // Verify.
            VerifyProdOrderCapacityNeedWithStartingTime(
              RoutingLine, ProductionOrder."No.", ProdOrderCapacityNeed."Send-Ahead Type"::" ", ProdOrderCapacityNeed."Time Type"::"Setup Time",
              ProductionOrder."Starting Time", 0);  // Use 0 for Allocated Time.
            VerifyProdOrderCapacityNeedWithStartingTime(
              RoutingLine, ProductionOrder."No.", ProdOrderCapacityNeed."Send-Ahead Type"::Both, ProdOrderCapacityNeed."Time Type"::"Run Time",
              ProductionOrder."Starting Time", RoutingLine."Run Time" * ProductionOrder.Quantity);  // Value required for Allocated Time.
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningRouteBackwardForwardConstrainedNotConstrainedMatchingZeroRunTime()
    var
        WorkCenter: Record "Work Center";
        ShopCalendarWorkingDays: Record "Shop Calendar Working Days";
        Item: Record Item;
        ShipmentDate: Date;
        PlanningFromDate: Date;
        PlanningToDate: Date;
    begin
        // [SCENARIO 202772] Backward and Forward planning of "Routing Line" with and without Constrained Resource ("Critical Load %" = 100)
        // [SCENARIO] with zero "Run Time" calculates the same value "Starting Date Time" = "Ending Date Time"
        // [FEATURE] [Planning] [Manufacturing] [Capacity] [Constrained Resource] [Schedule]
        Initialize();

        // [GIVEN] Work Center "W" and Sales Order "SO" of Item "I" with Routing "R" as demand for capacity of "W"
        // [GIVEN] Run Time of routing "R" is zero
        CreateShipmentPlanningFromToDatesSetup(ShipmentDate, PlanningFromDate, PlanningToDate);
        CreateWorkCenterWithShopCalendarWorkingDays(WorkCenter, ShopCalendarWorkingDays);
        CreateWorkCenterDemand(Item, WorkCenter."No.", 0, ShipmentDate);

        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] Single Requisition Line "RL1" is created
        // [THEN] "RL1"."Starting Date Time" = "RL1"."Ending Date Time" = SEDT
        // [WHEN] Refresh Planning Demand for "RL1" with Schedule Type = Forward
        // [THEN] "RL1" fields "Starting Date Time" and "RL1"."Ending Date Time" are the same = SEDT
        // [GIVEN] Delete "R1"
        // [GIVEN] Create Capacity Constrained Resource for "W" with "Critical Load %" = 100
        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] Single Requisition Line "RL2" is created
        // [THEN] "RL2" fields "Starting Date Time" and "RL2"."Ending Date Time" are the same = SEDT
        // [WHEN] Refresh Planning Demand for "RL2" with Schedule Type = Forward
        // [THEN] "RL2" fields "Starting Date Time" and "RL2"."Ending Date Time" are the same = SEDT
        PlanBackwardReplanForwardCreateConstrainedResourcePlanBackwardReplanForwardVerifyZeroRunTime(
          Item, WorkCenter."No.", ShipmentDate, PlanningFromDate, PlanningToDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningRouteBackwardForwardConstrainedNotConstrainedMatchingPositiveRunTime()
    var
        WorkCenter: Record "Work Center";
        ShopCalendarWorkingDays: Record "Shop Calendar Working Days";
        Item: Record Item;
        ShipmentDate: Date;
        PlanningFromDate: Date;
        PlanningToDate: Date;
    begin
        // [SCENARIO 202772] Backward and Forward planning of "Routing Line" with and without Constrained Resource ("Critical Load %" = 100) with positive "Run Time" calculates the same values of "Starting Date Time" and "Ending Date Time"
        // [FEATURE] [Planning] [Manufacturing] [Capacity] [Constrained Resource] [Schedule]
        Initialize();

        // [GIVEN] Work Center "W" and Sales Order "SO" of Item "I" with Routing "R" as demand for capacity of "W"
        // [GIVEN] Run Time of routing "R" is positive
        CreateShipmentPlanningFromToDatesSetup(ShipmentDate, PlanningFromDate, PlanningToDate);
        CreateWorkCenterWithShopCalendarWorkingDays(WorkCenter, ShopCalendarWorkingDays);
        CreateWorkCenterDemand(Item, WorkCenter."No.", LibraryRandom.RandIntInRange(5, 15), ShipmentDate);

        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] Single Requisition Line "RL1" is created
        // [THEN] "RL1"."Starting Date Time" = SDT, "RL1"."Ending Date Time" = EDT
        // [WHEN] Refresh Planning Demand for "RL1" with Schedule Type = Forward
        // [THEN] "RL1" fields "Starting Date Time" and "RL1"."Ending Date Time" are the same: "RL1"."Starting Date Time" = SDT, "RL1"."Ending Date Time" = EDT
        // [GIVEN] Delete "R1"
        // [GIVEN] Create Capacity Constrained Resource for "W" with "Critical Load %" = 100
        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] Single Requisition Line "RL2" is created
        // [THEN] "RL2" fields "Starting Date Time" and "RL2"."Ending Date Time" are the same: "RL1"."Starting Date Time" = SDT, "RL1"."Ending Date Time" = EDT
        // [WHEN] Refresh Planning Demand for "RL2" with Schedule Type = Forward
        // [THEN] "RL2" fields "Starting Date Time" and "RL2"."Ending Date Time" are the same: "RL1"."Starting Date Time" = SDT, "RL1"."Ending Date Time" = EDT
        PlanBackwardReplanForwardCreateConstrainedResourcePlanBackwardReplanForwardVerifyPositiveRunTime(
          Item, WorkCenter."No.", ShipmentDate, PlanningFromDate, PlanningToDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningRouteBackwardForwardConstrainedNotConstrainedMatchingAbsenceBeginningDayZeroRunTime()
    var
        Item: Record Item;
        WorkCenterNo: Code[20];
        ShipmentDate: Date;
        PlanningFromDate: Date;
        PlanningToDate: Date;
    begin
        // [SCENARIO 202772] Backward and Forward planning of "Routing Line" with and without Constrained Resource ("Critical Load %" = 100)
        // [SCENARIO] with zero "Run Time" and absence of Work Center in the beginning of the day calculates the same value "Starting Date Time" = "Ending Date Time"
        // [FEATURE] [Planning] [Manufacturing] [Capacity] [Constrained Resource] [Schedule]
        Initialize();

        // [GIVEN] Work Center "W" and Sales Order "SO" of Item "I" with Routing "R" as demand for capacity of "W"
        // [GIVEN] "W" is absent in the beginning of the day one day before "SO"."Shipment Date"
        // [GIVEN] Run Time of routing "R" is zero
        WorkCenterAndDemandAbsenceBeginningDay(Item, WorkCenterNo, ShipmentDate, PlanningFromDate, PlanningToDate, 0, false);

        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] Single Requisition Line "RL1" is created
        // [THEN] "RL1"."Starting Date Time" = "RL1"."Ending Date Time" = SEDT
        // [WHEN] Refresh Planning Demand for "RL1" with Schedule Type = Forward
        // [THEN] "RL1" fields "Starting Date Time" and "RL1"."Ending Date Time" are the same = SEDT
        // [GIVEN] Delete "R1"
        // [GIVEN] Create Capacity Constrained Resource for "W" with "Critical Load %" = 100
        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] Single Requisition Line "RL2" is created
        // [THEN] "RL2" fields "Starting Date Time" and "RL2"."Ending Date Time" are the same = SEDT
        // [WHEN] Refresh Planning Demand for "RL2" with Schedule Type = Forward
        // [THEN] "RL2" fields "Starting Date Time" and "RL2"."Ending Date Time" are the same = SEDT
        PlanBackwardReplanForwardCreateConstrainedResourcePlanBackwardReplanForwardVerifyZeroRunTime(
          Item, WorkCenterNo, ShipmentDate, PlanningFromDate, PlanningToDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningRouteBackwardForwardConstrainedNotConstrainedMatchingAbsenceBeginningDayOverlappedZeroRunTime()
    var
        Item: Record Item;
        WorkCenterNo: Code[20];
        ShipmentDate: Date;
        PlanningFromDate: Date;
        PlanningToDate: Date;
    begin
        // [SCENARIO 202772] Backward and Forward planning of "Routing Line" with and without Constrained Resource ("Critical Load %" = 100) with zero "Run Time" and absence of Work Center in the beginning of the day with overlapping with non-working hours
        // [FEATURE] [Planning] [Manufacturing] [Capacity] [Constrained Resource] [Schedule]
        Initialize();

        // [GIVEN] Work Center "W" and Sales Order "SO" of Item "I" with Routing "R" as demand for capacity of "W"
        // [GIVEN] "W" is absent in the beginning of the day one day before "SO"."Shipment Date". Absence of "W" starts before the beginning of workday and ends in the middle of the workday
        // [GIVEN] Run Time of routing "R" is zero
        WorkCenterAndDemandAbsenceBeginningDay(Item, WorkCenterNo, ShipmentDate, PlanningFromDate, PlanningToDate, 0, true);

        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] Single Requisition Line "RL1" is created
        // [THEN] "RL1"."Starting Date Time" = "RL1"."Ending Date Time" = SEDT
        // [WHEN] Refresh Planning Demand for "RL1" with Schedule Type = Forward
        // [THEN] "RL1" fields "Starting Date Time" and "RL1"."Ending Date Time" are the same = SEDT
        // [GIVEN] Delete "R1"
        // [GIVEN] Create Capacity Constrained Resource for "W" with "Critical Load %" = 100
        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] Single Requisition Line "RL2" is created
        // [THEN] "RL2" fields "Starting Date Time" and "RL2"."Ending Date Time" are the same = SEDT
        // [WHEN] Refresh Planning Demand for "RL2" with Schedule Type = Forward
        // [THEN] "RL2" fields "Starting Date Time" and "RL2"."Ending Date Time" are the same = SEDT
        PlanBackwardReplanForwardCreateConstrainedResourcePlanBackwardReplanForwardVerifyZeroRunTime(
          Item, WorkCenterNo, ShipmentDate, PlanningFromDate, PlanningToDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningRouteBackwardForwardConstrainedNotConstrainedMatchingAbsenceMiddleDayZeroRunTime()
    var
        Item: Record Item;
        WorkCenterNo: Code[20];
        ShipmentDate: Date;
        PlanningFromDate: Date;
        PlanningToDate: Date;
    begin
        // [SCENARIO 202772] Backward and Forward planning of "Routing Line" with and without Constrained Resource ("Critical Load %" = 100)
        // [SCENARIO] with zero "Run Time" and absence of Work Center in the middle of the day calculates the same value "Starting Date Time" = "Ending Date Time"
        // [FEATURE] [Planning] [Manufacturing] [Capacity] [Constrained Resource] [Schedule]
        Initialize();

        // [GIVEN] Work Center "W" and Sales Order "SO" of Item "I" with Routing "R" as demand for capacity of "W"
        // [GIVEN] "W" is absent in the middle of the day one day before "SO"."Shipment Date". Absence of "W" starts and ends in the middle of workday
        // [GIVEN] Run Time of routing "R" is zero
        WorkCenterAndDemandAbsenceMiddleDay(Item, WorkCenterNo, ShipmentDate, PlanningFromDate, PlanningToDate, 0);

        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] Single Requisition Line "RL1" is created
        // [THEN] "RL1"."Starting Date Time" = "RL1"."Ending Date Time" = SEDT
        // [WHEN] Refresh Planning Demand for "RL1" with Schedule Type = Forward
        // [THEN] "RL1" fields "Starting Date Time" and "RL1"."Ending Date Time" are the same = SEDT
        // [GIVEN] Delete "R1"
        // [GIVEN] Create Capacity Constrained Resource for "W" with "Critical Load %" = 100
        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] Single Requisition Line "RL2" is created
        // [THEN] "RL2" fields "Starting Date Time" and "RL2"."Ending Date Time" are the same = SEDT
        // [WHEN] Refresh Planning Demand for "RL2" with Schedule Type = Forward
        // [THEN] "RL2" fields "Starting Date Time" and "RL2"."Ending Date Time" are the same = SEDT
        PlanBackwardReplanForwardCreateConstrainedResourcePlanBackwardReplanForwardVerifyZeroRunTime(
          Item, WorkCenterNo, ShipmentDate, PlanningFromDate, PlanningToDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningRouteBackwardForwardConstrainedNotConstrainedMatchingAbsenceEndDayZeroRunTime()
    var
        Item: Record Item;
        WorkCenterNo: Code[20];
        ShipmentDate: Date;
        PlanningFromDate: Date;
        PlanningToDate: Date;
    begin
        // [SCENARIO 202772] Backward and Forward planning of "Routing Line" with and without Constrained Resource ("Critical Load %" = 100)
        // [SCENARIO] with zero "Run Time" and absence of Work Center in the ending of the day calculates the same value "Starting Date Time" = "Ending Date Time"
        // [FEATURE] [Planning] [Manufacturing] [Capacity] [Constrained Resource] [Schedule]
        Initialize();

        // [GIVEN] Work Center "W" and Sales Order "SO" of Item "I" with Routing "R" as demand for capacity of "W"
        // [GIVEN] "W" is absent in the ending of the day one day before "SO"."Shipment Date". Absence of "W" starts in the middle of the workday and ends with the ending of the workday
        // [GIVEN] Run Time of routing "R" is zero
        WorkCenterAndDemandAbsenceEndDay(Item, WorkCenterNo, ShipmentDate, PlanningFromDate, PlanningToDate, 0, false);

        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] Single Requisition Line "RL1" is created
        // [THEN] "RL1"."Starting Date Time" = "RL1"."Ending Date Time" = SEDT
        // [WHEN] Refresh Planning Demand for "RL1" with Schedule Type = Forward
        // [THEN] "RL1" fields "Starting Date Time" and "RL1"."Ending Date Time" are the same = SEDT
        // [GIVEN] Delete "R1"
        // [GIVEN] Create Capacity Constrained Resource for "W" with "Critical Load %" = 100
        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] Single Requisition Line "RL2" is created
        // [THEN] "RL2" fields "Starting Date Time" and "RL2"."Ending Date Time" are the same = SEDT
        // [WHEN] Refresh Planning Demand for "RL2" with Schedule Type = Forward
        // [THEN] "RL2" fields "Starting Date Time" and "RL2"."Ending Date Time" are the same = SEDT
        PlanBackwardReplanForwardCreateConstrainedResourcePlanBackwardReplanForwardVerifyZeroRunTime(
          Item, WorkCenterNo, ShipmentDate, PlanningFromDate, PlanningToDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningRouteBackwardForwardConstrainedNotConstrainedMatchingAbsenceEndDayOverlappedZeroRunTime()
    var
        Item: Record Item;
        WorkCenterNo: Code[20];
        ShipmentDate: Date;
        PlanningFromDate: Date;
        PlanningToDate: Date;
    begin
        // [SCENARIO 202772] Backward and Forward planning of "Routing Line" with and without Constrained Resource ("Critical Load %" = 100) with zero "Run Time" and absence of Work Center in the ending of the day with overlapping with non-working hours ca
        // [FEATURE] [Planning] [Manufacturing] [Capacity] [Constrained Resource] [Schedule]
        Initialize();

        // [GIVEN] Work Center "W" and Sales Order "SO" of Item "I" with Routing "R" as demand for capacity of "W"
        // [GIVEN] "W" is absent in the ending of the day one day before "SO"."Shipment Date". Absence of "W" starts in the middle of the workday and ends after the ending of the workday
        // [GIVEN] Run Time of routing "R" is zero
        WorkCenterAndDemandAbsenceEndDay(Item, WorkCenterNo, ShipmentDate, PlanningFromDate, PlanningToDate, 0, true);

        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] Single Requisition Line "RL1" is created
        // [THEN] "RL1"."Starting Date Time" = "RL1"."Ending Date Time" = SEDT
        // [WHEN] Refresh Planning Demand for "RL1" with Schedule Type = Forward
        // [THEN] "RL1" fields "Starting Date Time" and "RL1"."Ending Date Time" are the same = SEDT
        // [GIVEN] Delete "R1"
        // [GIVEN] Create Capacity Constrained Resource for "W" with "Critical Load %" = 100
        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] Single Requisition Line "RL2" is created
        // [THEN] "RL2" fields "Starting Date Time" and "RL2"."Ending Date Time" are the same = SEDT
        // [WHEN] Refresh Planning Demand for "RL2" with Schedule Type = Forward
        // [THEN] "RL2" fields "Starting Date Time" and "RL2"."Ending Date Time" are the same = SEDT
        PlanBackwardReplanForwardCreateConstrainedResourcePlanBackwardReplanForwardVerifyZeroRunTime(
          Item, WorkCenterNo, ShipmentDate, PlanningFromDate, PlanningToDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningRouteBackwardForwardConstrainedNotConstrainedMatchingAbsenceWholeDayZeroRunTime()
    var
        Item: Record Item;
        WorkCenterNo: Code[20];
        ShipmentDate: Date;
        PlanningFromDate: Date;
        PlanningToDate: Date;
    begin
        // [SCENARIO 202772] Backward and Forward planning of "Routing Line" with and without Constrained Resource ("Critical Load %" = 100)
        // [SCENARIO] with zero "Run Time" and absence of Work Center the whole day calculates the same value "Starting Date Time" = "Ending Date Time"
        // [FEATURE] [SCM] [Planning] [Manufacturing] [Capacity]
        Initialize();

        // [GIVEN] Work Center "W" and Sales Order "SO" of Item "I" with Routing "R" as demand for capacity of "W"
        // [GIVEN] "W" is absent the whole day one day before "SO"."Shipment Date". Absence of "W" starts with the beginning of the workday and ends with the ending of the workday
        // [GIVEN] Run Time of routing "R" is zero
        WorkCenterAndDemandAbsenceWholeDay(Item, WorkCenterNo, ShipmentDate, PlanningFromDate, PlanningToDate, 0, false);

        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] Single Requisition Line "RL1" is created
        // [THEN] "RL1"."Starting Date Time" = "RL1"."Ending Date Time" = SEDT
        // [WHEN] Refresh Planning Demand for "RL1" with Schedule Type = Forward
        // [THEN] "RL1" fields "Starting Date Time" and "RL1"."Ending Date Time" are the same = SEDT
        // [GIVEN] Delete "R1"
        // [GIVEN] Create Capacity Constrained Resource for "W" with "Critical Load %" = 100
        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] Single Requisition Line "RL2" is created
        // [THEN] "RL2" fields "Starting Date Time" and "RL2"."Ending Date Time" are the same = SEDT
        // [WHEN] Refresh Planning Demand for "RL2" with Schedule Type = Forward
        // [THEN] "RL2" fields "Starting Date Time" and "RL2"."Ending Date Time" are the same = SEDT
        PlanBackwardReplanForwardCreateConstrainedResourcePlanBackwardReplanForwardVerifyZeroRunTime(
          Item, WorkCenterNo, ShipmentDate, PlanningFromDate, PlanningToDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningRouteBackwardForwardConstrainedNotConstrainedMatchingAbsenceWholeDayOverlappedZeroRunTime()
    var
        Item: Record Item;
        WorkCenterNo: Code[20];
        ShipmentDate: Date;
        PlanningFromDate: Date;
        PlanningToDate: Date;
    begin
        // [SCENARIO 202772] Backward and Forward planning of "Routing Line" with and without Constrained Resource ("Critical Load %" = 100) with zero "Run Time" and absence of Work Center the whole day with overlapping with non-working hours calculates th
        // [FEATURE] [SCM] [Planning] [Manufacturing] [Capacity]
        Initialize();

        // [GIVEN] Work Center "W" and Sales Order "SO" of Item "I" with Routing "R" as demand for capacity of "W"
        // [GIVEN] "W" is absent the whole day one day before "SO"."Shipment Date". Absence of "W" starts before the beginning of the workday and ends after the ending of the workday
        // [GIVEN] Run Time of routing "R" is zero
        WorkCenterAndDemandAbsenceWholeDay(Item, WorkCenterNo, ShipmentDate, PlanningFromDate, PlanningToDate, 0, true);

        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] Single Requisition Line "RL1" is created
        // [THEN] "RL1"."Starting Date Time" = "RL1"."Ending Date Time" = SEDT
        // [WHEN] Refresh Planning Demand for "RL1" with Schedule Type = Forward
        // [THEN] "RL1" fields "Starting Date Time" and "RL1"."Ending Date Time" are the same = SEDT
        // [GIVEN] Delete "R1"
        // [GIVEN] Create Capacity Constrained Resource for "W" with "Critical Load %" = 100
        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] Single Requisition Line "RL2" is created
        // [THEN] "RL2" fields "Starting Date Time" and "RL2"."Ending Date Time" are the same = SEDT
        // [WHEN] Refresh Planning Demand for "RL2" with Schedule Type = Forward
        // [THEN] "RL2" fields "Starting Date Time" and "RL2"."Ending Date Time" are the same = SEDT
        PlanBackwardReplanForwardCreateConstrainedResourcePlanBackwardReplanForwardVerifyZeroRunTime(
          Item, WorkCenterNo, ShipmentDate, PlanningFromDate, PlanningToDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningRouteBackwardForwardConstrainedNotConstrainedMatchingAbsenceBeginningDayPositiveRunTime()
    var
        Item: Record Item;
        WorkCenterNo: Code[20];
        ShipmentDate: Date;
        PlanningFromDate: Date;
        PlanningToDate: Date;
    begin
        // [SCENARIO 202772] Backward and Forward planning of "Routing Line" with and without Constrained Resource ("Critical Load %" = 100)
        // [SCENARIO] with positive "Run Time" and absence of Work Center in the beginning of the day calculates the same values of "Starting Date Time"
        // [FEATURE] [Planning] [Manufacturing] [Capacity] [Constrained Resource] [Schedule]
        Initialize();

        // [GIVEN] Work Center "W" and Sales Order "SO" of Item "I" with Routing "R" as demand for capacity of "W"
        // [GIVEN] "W" is absent in the beginning of the day one day before "SO"."Shipment Date"
        // [GIVEN] Run Time of routing "R" is positive
        WorkCenterAndDemandAbsenceBeginningDay(
          Item, WorkCenterNo, ShipmentDate, PlanningFromDate, PlanningToDate, LibraryRandom.RandIntInRange(60, 120), false);

        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] Single Requisition Line "RL1" is created
        // [THEN] "RL1"."Starting Date Time" = SDT, "RL1"."Ending Date Time" = EDT
        // [WHEN] Refresh Planning Demand for "RL1" with Schedule Type = Forward
        // [THEN] "RL1" fields "Starting Date Time" and "RL1"."Ending Date Time" are the same: "RL1"."Starting Date Time" = SDT, "RL1"."Ending Date Time" = EDT
        // [GIVEN] Delete "R1"
        // [GIVEN] Create Capacity Constrained Resource for "W" with "Critical Load %" = 100
        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] Single Requisition Line "RL2" is created
        // [THEN] "RL2" fields "Starting Date Time" and "RL2"."Ending Date Time" are the same: "RL1"."Starting Date Time" = SDT, "RL1"."Ending Date Time" = EDT
        // [WHEN] Refresh Planning Demand for "RL2" with Schedule Type = Forward
        // [THEN] "RL2" fields "Starting Date Time" and "RL2"."Ending Date Time" are the same: "RL1"."Starting Date Time" = SDT, "RL1"."Ending Date Time" = EDT
        PlanBackwardReplanForwardCreateConstrainedResourcePlanBackwardReplanForwardVerifyPositiveRunTime(
          Item, WorkCenterNo, ShipmentDate, PlanningFromDate, PlanningToDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningRouteBackwardForwardConstrainedNotConstrainedMatchingAbsenceBeginningDayOverlappedPositiveRunTime()
    var
        Item: Record Item;
        WorkCenterNo: Code[20];
        ShipmentDate: Date;
        PlanningFromDate: Date;
        PlanningToDate: Date;
    begin
        // [SCENARIO 202772] Backward and Forward planning of "Routing Line" with and without Constrained Resource ("Critical Load %" = 100)
        // [SCENARIO] with positive "Run Time" and absence of Work Center in the beginning of the day with overlapping with non-working hours
        // [FEATURE] [Planning] [Manufacturing] [Capacity] [Constrained Resource] [Schedule]
        Initialize();

        // [GIVEN] Work Center "W" and Sales Order "SO" of Item "I" with Routing "R" as demand for capacity of "W"
        // [GIVEN] "W" is absent in the beginning of the day one day before "SO"."Shipment Date". Absence of "W" starts before the beginning of workday and ends in the middle of the workday
        // [GIVEN] Run Time of routing "R" is positive
        WorkCenterAndDemandAbsenceBeginningDay(
          Item, WorkCenterNo, ShipmentDate, PlanningFromDate, PlanningToDate, LibraryRandom.RandIntInRange(60, 120), true);

        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] Single Requisition Line "RL1" is created
        // [THEN] "RL1"."Starting Date Time" = SDT, "RL1"."Ending Date Time" = EDT
        // [WHEN] Refresh Planning Demand for "RL1" with Schedule Type = Forward
        // [THEN] "RL1" fields "Starting Date Time" and "RL1"."Ending Date Time" are the same: "RL1"."Starting Date Time" = SDT, "RL1"."Ending Date Time" = EDT
        // [GIVEN] Delete "R1"
        // [GIVEN] Create Capacity Constrained Resource for "W" with "Critical Load %" = 100
        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] Single Requisition Line "RL2" is created
        // [THEN] "RL2" fields "Starting Date Time" and "RL2"."Ending Date Time" are the same: "RL1"."Starting Date Time" = SDT, "RL1"."Ending Date Time" = EDT
        // [WHEN] Refresh Planning Demand for "RL2" with Schedule Type = Forward
        // [THEN] "RL2" fields "Starting Date Time" and "RL2"."Ending Date Time" are the same: "RL1"."Starting Date Time" = SDT, "RL1"."Ending Date Time" = EDT
        PlanBackwardReplanForwardCreateConstrainedResourcePlanBackwardReplanForwardVerifyPositiveRunTime(
          Item, WorkCenterNo, ShipmentDate, PlanningFromDate, PlanningToDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningRouteBackwardForwardConstrainedNotConstrainedMatchingAbsenceMiddleDayPositiveRunTime()
    var
        Item: Record Item;
        WorkCenterNo: Code[20];
        ShipmentDate: Date;
        PlanningFromDate: Date;
        PlanningToDate: Date;
    begin
        // [SCENARIO 202772] Backward and Forward planning of "Routing Line" with and without Constrained Resource ("Critical Load %" = 100)
        // [SCENARIO] with positive "Run Time" and absence of Work Center in the middle of the day calculates the same values of "Starting Date Time"
        // [FEATURE] [Planning] [Manufacturing] [Capacity] [Constrained Resource] [Schedule]
        Initialize();

        // [GIVEN] Work Center "W" and Sales Order "SO" of Item "I" with Routing "R" as demand for capacity of "W"
        // [GIVEN] "W" is absent in the middle of the day one day before "SO"."Shipment Date". Absence of "W" starts and ends in the middle of workday
        // [GIVEN] Run Time of routing "R" is positive
        WorkCenterAndDemandAbsenceMiddleDay(
          Item, WorkCenterNo, ShipmentDate, PlanningFromDate, PlanningToDate, LibraryRandom.RandIntInRange(60, 120));

        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] Single Requisition Line "RL1" is created
        // [THEN] "RL1"."Starting Date Time" = SDT, "RL1"."Ending Date Time" = EDT
        // [WHEN] Refresh Planning Demand for "RL1" with Schedule Type = Forward
        // [THEN] "RL1" fields "Starting Date Time" and "RL1"."Ending Date Time" are the same: "RL1"."Starting Date Time" = SDT, "RL1"."Ending Date Time" = EDT
        // [GIVEN] Delete "R1"
        // [GIVEN] Create Capacity Constrained Resource for "W" with "Critical Load %" = 100
        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] Single Requisition Line "RL2" is created
        // [THEN] "RL2" fields "Starting Date Time" and "RL2"."Ending Date Time" are the same: "RL1"."Starting Date Time" = SDT, "RL1"."Ending Date Time" = EDT
        // [WHEN] Refresh Planning Demand for "RL2" with Schedule Type = Forward
        // [THEN] "RL2" fields "Starting Date Time" and "RL2"."Ending Date Time" are the same: "RL1"."Starting Date Time" = SDT, "RL1"."Ending Date Time" = EDT
        PlanBackwardReplanForwardCreateConstrainedResourcePlanBackwardReplanForwardVerifyPositiveRunTime(
          Item, WorkCenterNo, ShipmentDate, PlanningFromDate, PlanningToDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningRouteBackwardForwardConstrainedNotConstrainedMatchingAbsenceEndDayPositiveRunTime()
    var
        Item: Record Item;
        WorkCenterNo: Code[20];
        ShipmentDate: Date;
        PlanningFromDate: Date;
        PlanningToDate: Date;
    begin
        // [SCENARIO 202772] Backward and Forward planning of "Routing Line" with and without Constrained Resource ("Critical Load %" = 100)
        // [SCENARIO] with positive "Run Time" and absence of Work Center in the ending of the day calculates the same values of "Starting Date Time"
        // [FEATURE] [Planning] [Manufacturing] [Capacity] [Constrained Resource] [Schedule]
        Initialize();

        // [GIVEN] Work Center "W" and Sales Order "SO" of Item "I" with Routing "R" as demand for capacity of "W"
        // [GIVEN] "W" is absent in the ending of the day one day before "SO"."Shipment Date". Absence of "W" starts in the middle of the workday and ends with the ending of the workday
        // [GIVEN] Run Time of routing "R" is positive
        WorkCenterAndDemandAbsenceEndDay(
          Item, WorkCenterNo, ShipmentDate, PlanningFromDate, PlanningToDate, LibraryRandom.RandIntInRange(60, 120), false);

        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] Single Requisition Line "RL1" is created
        // [THEN] "RL1"."Starting Date Time" = SDT, "RL1"."Ending Date Time" = EDT
        // [WHEN] Refresh Planning Demand for "RL1" with Schedule Type = Forward
        // [THEN] "RL1" fields "Starting Date Time" and "RL1"."Ending Date Time" are the same: "RL1"."Starting Date Time" = SDT, "RL1"."Ending Date Time" = EDT
        // [GIVEN] Delete "R1"
        // [GIVEN] Create Capacity Constrained Resource for "W" with "Critical Load %" = 100
        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] Single Requisition Line "RL2" is created
        // [THEN] "RL2" fields "Starting Date Time" and "RL2"."Ending Date Time" are the same: "RL1"."Starting Date Time" = SDT, "RL1"."Ending Date Time" = EDT
        // [WHEN] Refresh Planning Demand for "RL2" with Schedule Type = Forward
        // [THEN] "RL2" fields "Starting Date Time" and "RL2"."Ending Date Time" are the same: "RL1"."Starting Date Time" = SDT, "RL1"."Ending Date Time" = EDT
        PlanBackwardReplanForwardCreateConstrainedResourcePlanBackwardReplanForwardVerifyPositiveRunTime(
          Item, WorkCenterNo, ShipmentDate, PlanningFromDate, PlanningToDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningRouteBackwardForwardConstrainedNotConstrainedMatchingAbsenceEndDayOverlappedPositiveRunTime()
    var
        Item: Record Item;
        WorkCenterNo: Code[20];
        ShipmentDate: Date;
        PlanningFromDate: Date;
        PlanningToDate: Date;
    begin
        // [SCENARIO 202772] Backward and Forward planning of "Routing Line" with and without Constrained Resource ("Critical Load %" = 100)
        // [SCENARIO] with positive "Run Time" and absence of Work Center in the ending of the day with overlapping with non-working hours
        // [FEATURE] [Planning] [Manufacturing] [Capacity] [Constrained Resource] [Schedule]
        Initialize();

        // [GIVEN] Work Center "W" and Sales Order "SO" of Item "I" with Routing "R" as demand for capacity of "W"
        // [GIVEN] "W" is absent in the ending of the day one day before "SO"."Shipment Date". Absence of "W" starts in the middle of the workday and ends after the ending of the workday
        // [GIVEN] Run Time of routing "R" is positive
        WorkCenterAndDemandAbsenceEndDay(
          Item, WorkCenterNo, ShipmentDate, PlanningFromDate, PlanningToDate, LibraryRandom.RandIntInRange(60, 120), true);

        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] Single Requisition Line "RL1" is created
        // [THEN] "RL1"."Starting Date Time" = SDT, "RL1"."Ending Date Time" = EDT
        // [WHEN] Refresh Planning Demand for "RL1" with Schedule Type = Forward
        // [THEN] "RL1" fields "Starting Date Time" and "RL1"."Ending Date Time" are the same: "RL1"."Starting Date Time" = SDT, "RL1"."Ending Date Time" = EDT
        // [GIVEN] Delete "R1"
        // [GIVEN] Create Capacity Constrained Resource for "W" with "Critical Load %" = 100
        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] Single Requisition Line "RL2" is created
        // [THEN] "RL2" fields "Starting Date Time" and "RL2"."Ending Date Time" are the same: "RL1"."Starting Date Time" = SDT, "RL1"."Ending Date Time" = EDT
        // [WHEN] Refresh Planning Demand for "RL2" with Schedule Type = Forward
        // [THEN] "RL2" fields "Starting Date Time" and "RL2"."Ending Date Time" are the same: "RL1"."Starting Date Time" = SDT, "RL1"."Ending Date Time" = EDT
        PlanBackwardReplanForwardCreateConstrainedResourcePlanBackwardReplanForwardVerifyPositiveRunTime(
          Item, WorkCenterNo, ShipmentDate, PlanningFromDate, PlanningToDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningRouteBackwardForwardConstrainedNotConstrainedMatchingAbsenceWholeDayPositiveRunTime()
    var
        Item: Record Item;
        WorkCenterNo: Code[20];
        ShipmentDate: Date;
        PlanningFromDate: Date;
        PlanningToDate: Date;
    begin
        // [SCENARIO 202772] Backward and Forward planning of "Routing Line" with and without Constrained Resource ("Critical Load %" = 100)
        // [SCENARIO] with positive "Run Time" and absence of Work Center the whole day calculates the same values of "Starting Date Time"
        // [FEATURE] [Planning] [Manufacturing] [Capacity] [Constrained Resource] [Schedule]
        Initialize();

        // [GIVEN] Work Center "W" and Sales Order "SO" of Item "I" with Routing "R" as demand for capacity of "W"
        // [GIVEN] "W" is absent the whole day one day before "SO"."Shipment Date". Absence of "W" starts with the beginning of the workday and ends with the ending of the workday
        // [GIVEN] Run Time of routing "R" is positive
        WorkCenterAndDemandAbsenceWholeDay(
          Item, WorkCenterNo, ShipmentDate, PlanningFromDate, PlanningToDate, LibraryRandom.RandIntInRange(60, 120), false);

        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] Single Requisition Line "RL1" is created
        // [THEN] "RL1"."Starting Date Time" = SDT, "RL1"."Ending Date Time" = EDT
        // [WHEN] Refresh Planning Demand for "RL1" with Schedule Type = Forward
        // [THEN] "RL1" fields "Starting Date Time" and "RL1"."Ending Date Time" are the same: "RL1"."Starting Date Time" = SDT, "RL1"."Ending Date Time" = EDT
        // [GIVEN] Delete "R1"
        // [GIVEN] Create Capacity Constrained Resource for "W" with "Critical Load %" = 100
        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] Single Requisition Line "RL2" is created
        // [THEN] "RL2" fields "Starting Date Time" and "RL2"."Ending Date Time" are the same: "RL1"."Starting Date Time" = SDT, "RL1"."Ending Date Time" = EDT
        // [WHEN] Refresh Planning Demand for "RL2" with Schedule Type = Forward
        // [THEN] "RL2" fields "Starting Date Time" and "RL2"."Ending Date Time" are the same: "RL1"."Starting Date Time" = SDT, "RL1"."Ending Date Time" = EDT
        PlanBackwardReplanForwardCreateConstrainedResourcePlanBackwardReplanForwardVerifyPositiveRunTime(
          Item, WorkCenterNo, ShipmentDate, PlanningFromDate, PlanningToDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningRouteBackwardForwardConstrainedNotConstrainedMatchingAbsenceWholeDayOverlappedPositiveRunTime()
    var
        Item: Record Item;
        WorkCenterNo: Code[20];
        ShipmentDate: Date;
        PlanningFromDate: Date;
        PlanningToDate: Date;
    begin
        // [SCENARIO 202772] Backward and Forward planning of "Routing Line" with and without Constrained Resource ("Critical Load %" = 100)
        // [SCENARIO] with positive "Run Time" and absence of Work Center the whole day with overlapping with non-working hours calculate
        // [FEATURE] [Planning] [Manufacturing] [Capacity] [Constrained Resource] [Schedule]
        Initialize();

        // [GIVEN] Work Center "W" and Sales Order "SO" of Item "I" with Routing "R" as demand for capacity of "W"
        // [GIVEN] "W" is absent the whole day one day before "SO"."Shipment Date". Absence of "W" starts before the beginning of the workday and ends after the ending of the workday
        // [GIVEN] Run Time of routing "R" is positive
        WorkCenterAndDemandAbsenceWholeDay(
          Item, WorkCenterNo, ShipmentDate, PlanningFromDate, PlanningToDate, LibraryRandom.RandIntInRange(60, 120), true);

        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] Single Requisition Line "RL1" is created
        // [THEN] "RL1"."Starting Date Time" = SDT, "RL1"."Ending Date Time" = EDT
        // [WHEN] Refresh Planning Demand for "RL1" with Schedule Type = Forward
        // [THEN] "RL1" fields "Starting Date Time" and "RL1"."Ending Date Time" are the same: "RL1"."Starting Date Time" = SDT, "RL1"."Ending Date Time" = EDT
        // [GIVEN] Delete "R1"
        // [GIVEN] Create Capacity Constrained Resource for "W" with "Critical Load %" = 100
        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] Single Requisition Line "RL2" is created
        // [THEN] "RL2" fields "Starting Date Time" and "RL2"."Ending Date Time" are the same: "RL1"."Starting Date Time" = SDT, "RL1"."Ending Date Time" = EDT
        // [WHEN] Refresh Planning Demand for "RL2" with Schedule Type = Forward
        // [THEN] "RL2" fields "Starting Date Time" and "RL2"."Ending Date Time" are the same: "RL1"."Starting Date Time" = SDT, "RL1"."Ending Date Time" = EDT
        PlanBackwardReplanForwardCreateConstrainedResourcePlanBackwardReplanForwardVerifyPositiveRunTime(
          Item, WorkCenterNo, ShipmentDate, PlanningFromDate, PlanningToDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StartingEndingDateTimePlanningRoutingLineToProdOrderRoutingLineCorresponding()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        Item: Record Item;
        TempProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary;
        PlanningRoutingLine: Record "Planning Routing Line";
        Qty: Decimal;
    begin
        // [SCENARIO 203921] For "Send-Ahead Quantity" the results of calculating of fields "Starting Date-Time" and "Ending Date-Time" by regenerative plan
        // [SCENARIO] for production order must correspond to the ones of the refreshing of production order.
        // [FEATURE] [Planning] [Manufacturing] [Capacity] [Send-Ahead Quantity]
        Initialize();

        // [GIVEN] Manufacturing Item "I" with serial routing with 4 lines L1, L2, L3, L4: L2 and L3 have "Send-Ahead Quantity" > 1.
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);
        CreateRoutingWithSendahead(RoutingHeader, WorkCenter."No.", 60, LibraryRandom.RandIntInRange(2, 5));
        CreateLotProdMakeToOrderItemWithRoutingNo(Item, RoutingHeader."No.");

        // [GIVEN] Sales Order as Demand for "I".
        Qty := LibraryRandom.RandIntInRange(10, 20);
        CreateSalesOrderWithQuantity(Item."No.", Qty);

        CalculateProductionOrder(TempProdOrderRoutingLine, Item, Qty);

        // [WHEN] Calculate Regenerative Plan for "I"
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());
        PlanningRoutingLine.SetRange("Work Center No.", WorkCenter."No.");

        // [THEN] Corresponding data in "Planning Routing Line" table contains 4 Lines;
        Assert.RecordCount(PlanningRoutingLine, 4);

        // [THEN] Each of these 4 lines has the same values of "Starting Date-Time" and "Ending Date-Time" fields as if these fields were calculated for "Production Order" with the same Quantity.
        TempProdOrderRoutingLine.FindSet();
        repeat
            PlanningRoutingLine.SetRange("Operation No.", TempProdOrderRoutingLine."Operation No.");
            PlanningRoutingLine.FindFirst();
            PlanningRoutingLine.TestField("Starting Date-Time", TempProdOrderRoutingLine."Starting Date-Time");
            PlanningRoutingLine.TestField("Ending Date-Time", TempProdOrderRoutingLine."Ending Date-Time");
        until TempProdOrderRoutingLine.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesForecastWithBlankLocationCodeForAssemblyItemWhenComponentsAtLocation()
    var
        Item: Record Item;
    begin
        // [FEATURE] [Production Forecast] [Assembly] [Components At Location]
        // [SCENARIO 201871] For Assembly Item blank location in Sales Production Forecast must stay blank after Regeneration Plan Calculating, Location for Components can't be used for non-component forecast.

        // [GIVEN] Item "I" with "Replenishment System" = Assembly, Current Production Forecast "F", Forecast Entry with type Sales for "I" with blank location and Quantity "Q"
        // [GIVEN] Location "L" is the Location for Components
        // [GIVEN] Item "I" has some inventory at "L"
        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] only one Requisition Line "R" is created, "R"."Location Code" is blank, "R"."Quantity" = "Q"
        SalesForecastWithBlankLocationCodeForAssemblyProdOrderItemWhenComponentsAtLocation(Item."Replenishment System"::Assembly);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesForecastWithBlankLocationCodeForProdOrderItemWhenComponentsAtLocation()
    var
        Item: Record Item;
    begin
        // [FEATURE] [Production Forecast] [Manufacturing] [Components At Location]
        // [SCENARIO 201871]  For Prod. Order Item blank location in Sales Production Forecast must stay blank after Regeneration Plan Calculating, Location for Components can't be used for non-component forecast.

        // [GIVEN] Item "I" with "Replenishment System" = "Prod. Order", Current Production Forecast "F", Forecast Entry with type Sales for "I" with blank location and Quantity "Q"
        // [GIVEN] Location "L" is the Location for Components
        // [GIVEN] Item "I" has some inventory at "L"
        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] only one Requisition Line "R" is created, "R"."Location Code" is blank, "R"."Quantity" = "Q"
        SalesForecastWithBlankLocationCodeForAssemblyProdOrderItemWhenComponentsAtLocation(Item."Replenishment System"::"Prod. Order");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ComponentForecastWithBlankLocationCodeForAssemblyItemWhenComponentsAtLocation()
    var
        Item: Record Item;
    begin
        // [FEATURE] [Production Forecast] [Assembly] [Components At Location]
        // [SCENARIO 201871] For Assembly Item blank location in Component Production Forecast must stay blank after Regeneration Plan Calculating, Location for Components in can't be used for non-component forecast.

        // [GIVEN] Item "I" with "Replenishment System" = Assembly, Current Production Forecast "F", Forecast Entry with type Component for "I" with blank location and Quantity "Q"
        // [GIVEN] Location "L" is the Location for Components
        // [GIVEN] Item "I" has inventory "IL" at "L"
        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] only one Requisition Line "R" is created, "R"."Location Code" is "L".Code, "R"."Quantity" = "Q" - "IL"
        ComponentForecastWithBlankLocationCodeForAssemblyProdOrderItemWhenComponentsAtLocation(Item."Replenishment System"::Assembly);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ComponentForecastWithBlankLocationCodeForProdOrderItemWhenComponentsAtLocation()
    var
        Item: Record Item;
    begin
        // [FEATURE] [Production Forecast] [Manufacturing] [Components At Location]
        // [SCENARIO 201871] For Prod. Order Item blank location in Component Production Forecast must stay blank after Regeneration Plan Calculating, Location for Components in can't be used for non-component forecast.

        // [GIVEN] Item "I" with "Replenishment System" = "Prod. Order", Current Production Forecast "F", Forecast Entry with type Component for "I" with blank location and Quantity "Q"
        // [GIVEN] Location "L" is the Location for Components
        // [GIVEN] Item "I" has inventory "IL" at "L"
        // [WHEN] Calculate Regenerative Plan for "I"
        // [THEN] only one Requisition Line "R" is created, "R"."Location Code" is "L".Code, "R"."Quantity" = "Q" - "IL"
        ComponentForecastWithBlankLocationCodeForAssemblyProdOrderItemWhenComponentsAtLocation(
          Item."Replenishment System"::"Prod. Order");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ScrapPctInProdBOMLineCopiedFromComponent()
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        Item: Record Item;
    begin
        // [FEATURE] [Production BOM] [Scrap] [UT]
        // [SCENARIO 218724] Scrap % in production BOM line should be copied from the component item when the item No. is validated

        Initialize();

        // [GIVEN] Item "I" with scrap % = "X"
        LibraryInventory.CreateItem(Item);
        Item.Validate("Scrap %", LibraryRandom.RandInt(20));
        Item.Modify(true);

        // [GIVEN] Production BOM with one line
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");
        ProductionBOMLine.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProductionBOMLine.Validate(Type, ProductionBOMLine.Type::Item);

        // [WHEN] Set item "I" as the component in the BOM line
        ProductionBOMLine.Validate("No.", Item."No.");

        // [THEN] Scrap % in the BOM line is "X"
        ProductionBOMLine.TestField("Scrap %", Item."Scrap %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ActiveRoutingVersionBinCodesSalesOrderSameLocation()
    var
        RoutingLine: Record "Routing Line";
        WorkCenter: array[2] of Record "Work Center";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Planning] [Routing Version]
        // [SCENARIO 226948] From- and To- production bin codes are transferred from "Work Center" of active version of routing to "Prod. Order Routing Line" when planning for "Sales Order" at the same location as "Work Center"
        Initialize();

        // [GIVEN] Lication "L" with bin mandatory
        // [GIVEN] Two work center "W1" and "W2" at "L" with specified From- and To- production bin codes
        // [GIVEN] Routing "R" has line "L" and version line "V", "W1" belongs to "L", "W2" belongs to "V"
        CreateVersionRoutingLine(RoutingLine, WorkCenter);

        // [GIVEN] Item "I" with routing "R": "Reordering Policy" = "Lot-for-Lot"
        CreateLotProdMakeToOrderItemWithRoutingNo(Item, RoutingLine."Routing No.");

        // [GIVEN] Sales Order "S" for "I" at "L"
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo(),
          Item."No.", 1, WorkCenter[1]."Location Code", WorkDate());

        // [WHEN] calculate regenerative plan for "I" and carry out messages
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());
        CarryOutActionMessageOnPlanningWorksheet(Item."No.");

        // [THEN] Production order for "I" has "Bin Code" = "W2"."From-Production Bin Code",
        // [THEN] "Prod. Order Routing Line" "RL" : "RL"."From-Production Bin Code" = "W2"."From-Production Bin Code", "RL"."To-Production Bin Code" = "W2"."To-Production Bin Code"
        VerifyProductionOrderWithRoutingLine(WorkCenter[2], Item."No.", RoutingLine."Operation No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ActiveRoutingVersionBinCodesSalesOrderBlankLocation()
    var
        RoutingLine: Record "Routing Line";
        WorkCenter: array[2] of Record "Work Center";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Planning] [Routing Version]
        // [SCENARIO 226948] From- and To- production bin codes are transferred from "Work Center" of active version of routing to "Prod. Order Routing Line" when planning for Sales Order with blank location
        Initialize();

        // [GIVEN] Lication "L" with bin mandatory
        // [GIVEN] Two work center "W1" and "W2" at "L" with specified From- and To- production bin codes
        // [GIVEN] Routing "R" has line "L" and version line "V", "W1" belongs to "L", "W2" belongs to "V"
        CreateVersionRoutingLine(RoutingLine, WorkCenter);

        // [GIVEN] Item "I" with routing "R": "Reordering Policy" = "Lot-for-Lot"
        CreateLotProdMakeToOrderItemWithRoutingNo(Item, RoutingLine."Routing No.");

        // [GIVEN] Sales Order "S" for "I" with blank location
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo(), Item."No.", 1, '', WorkDate());

        // [WHEN] calculate regenerative plan for "I" and carry out messages
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());
        CarryOutActionMessageOnPlanningWorksheet(Item."No.");

        // [THEN] Production order for "I" has "Bin Code" = "W2"."From-Production Bin Code",
        // [THEN] "Prod. Order Routing Line" "RL" : "RL"."From-Production Bin Code" = "W2"."From-Production Bin Code", "RL"."To-Production Bin Code" = "W2"."To-Production Bin Code"
        VerifyProductionOrderWithRoutingLineBlankLocationAndBins(Item."No.", RoutingLine."Operation No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ActiveRoutingVersionBinCodesReorderPoint()
    var
        RoutingLine: Record "Routing Line";
        WorkCenter: array[2] of Record "Work Center";
        Item: Record Item;
    begin
        // [FEATURE] [Planning] [Routing Version]
        // [SCENARIO 226948] From- and To- production bin codes are transferred from "Work Center" of active version of routing to "Prod. Order Routing Line" when planning for Item reorder point
        Initialize();

        // [GIVEN] Lication "L" with bin mandatory
        // [GIVEN] Two work center "W1" and "W2" at "L" with specified From- and To- production bin codes
        // [GIVEN] Routing "R" has line "L" and version line "V", "W1" belongs to "L", "W2" belongs to "V"
        CreateVersionRoutingLine(RoutingLine, WorkCenter);

        // [GIVEN] Item "I" with routing "R": "Reordering Policy" = "Fixed Reorder Qty.", "Reorder Point" and "Reorder Quantity" specified
        CreateFixedReorderQtyItemWithRoutingNo(Item, RoutingLine."Routing No.");

        // [WHEN] calculate regenerative plan for "I" and carry out messages
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());
        CarryOutActionMessageOnPlanningWorksheet(Item."No.");

        // [THEN] Production order for "I" has "Bin Code" = "W2"."From-Production Bin Code",
        // [THEN] "Prod. Order Routing Line" "RL" : "RL"."From-Production Bin Code" = "W2"."From-Production Bin Code", "RL"."To-Production Bin Code" = "W2"."To-Production Bin Code"
        VerifyProductionOrderWithRoutingLine(WorkCenter[2], Item."No.", RoutingLine."Operation No.");
    end;

    [Test]
    [HandlerFunctions('CreateOrderFromSalesModalPageHandler,CheckProdOrderStatusModalPageHandler,SimpleMessageHandler')]
    [Scope('OnPrem')]
    procedure ReducedQtyInSalesPlannedAsOrderToOrderLeadsToReducingQtyInBoundProductionOrder()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ProductionOrder: Record "Production Order";
        RequisitionLine: Record "Requisition Line";
    begin
        // [FEATURE] [Planning] [Production] [Sales] [Order-to-Order Binding]
        // [SCENARIO 300468] When a user reduces quantity on sales line bound to a prod. order as order-to-order, and runs planning, the program suggests reducing the production order accordingly.
        Initialize();

        // [GIVEN] Production item set up for "Maximum Qty." reordering policy, "Maximum Inventory" = 16, "Order Multiple" = 4.
        // [GIVEN] "Order Multiple" setting being greater than 1 is crucial for the test.
        CreateProdOrderItem(Item, Item."Reordering Policy"::"Maximum Qty.", LibraryRandom.RandIntInRange(2, 5), '');
        Item.Validate("Maximum Inventory", LibraryRandom.RandIntInRange(10, 20));
        Item.Modify(true);

        // [GIVEN] 16 pcs of the item are in stock (maximum inventory).
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", '', '', Item."Maximum Inventory");
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Create sales order for 100 pcs.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", LibraryRandom.RandIntInRange(100, 200), '', WorkDate());

        // [GIVEN] Create firm planned production order out of the sales order using "Planning" functionality to cover the demand.
        // [GIVEN] The new production order has quantity = 100 pcs.
        // [GIVEN] The production is reserved to the sales with order-to-order link.
        LibraryManufacturing.CreateProdOrderUsingPlanning(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", SalesHeader."No.", Item."No.");

        // [GIVEN] Reduce the quantity on the sales line to 60.
        SalesLine.Find();
        SalesLine.Validate(Quantity, LibraryRandom.RandIntInRange(30, 60));
        SalesLine.Modify(true);

        // [WHEN] Calculate regenerative plan for the item in order to replan the production order.
        Item.SetRecFilter();
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());

        // [THEN] The planning engine suggests reducing quantity on the production order to 60 so it matches the sales.
        FindRequisitionLine(RequisitionLine, SalesLine."No.");
        RequisitionLine.TestField(Quantity, SalesLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('CreateOrderFromSalesModalPageHandler,CheckProdOrderStatusModalPageHandler,SimpleMessageHandler')]
    procedure ReducedQtyInSalesPlannedAsOrderToOrderLeadsToReducingQtyInBoundProdOrderRespectPlanParamsOn()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ProductionOrder: Record "Production Order";
        RequisitionLine: Record "Requisition Line";
    begin
        // [FEATURE] [Planning] [Production] [Sales] [Order-to-Order Binding]
        // [SCENARIO 300468] When a user reduces quantity on sales line bound to a prod. order as order-to-order, and runs planning with "Respect Planning Parameters" setting turned on, the program suggests reducing the production order accordingly.
        Initialize();

        // [GIVEN] Production item set up for "Maximum Qty." reordering policy, "Maximum Inventory" = 16, "Order Multiple" = 4.
        // [GIVEN] "Order Multiple" setting being greater than 1 is crucial for the test.
        CreateProdOrderItem(Item, Item."Reordering Policy"::"Maximum Qty.", LibraryRandom.RandIntInRange(2, 5), '');
        Item.Validate("Maximum Inventory", LibraryRandom.RandIntInRange(10, 20));
        Item.Modify(true);

        // [GIVEN] 16 pcs of the item are in stock (maximum inventory).
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", '', '', Item."Maximum Inventory");
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Create sales order for 100 pcs.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", LibraryRandom.RandIntInRange(100, 200), '', WorkDate());

        // [GIVEN] Create firm planned production order out of the sales order using "Planning" functionality to cover the demand.
        // [GIVEN] The new production order has quantity = 100 pcs.
        // [GIVEN] The production is reserved to the sales with order-to-order link.
        LibraryManufacturing.CreateProdOrderUsingPlanning(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", SalesHeader."No.", Item."No.");

        // [GIVEN] Reduce the quantity on the sales line to 60.
        SalesLine.Find();
        SalesLine.Validate(Quantity, LibraryRandom.RandIntInRange(30, 60));
        SalesLine.Modify(true);

        // [WHEN] Calculate regenerative plan with respect planning parameters setting turned on in order to replan the production order.
        Item.SetRecFilter();
        LibraryPlanning.CalcRegenPlanForPlanWkshPlanningParams(Item, WorkDate(), WorkDate(), true);

        // [THEN] The planning engine suggests reducing quantity on the production order to 60 so it matches the sales.
        FindRequisitionLine(RequisitionLine, SalesLine."No.");
        RequisitionLine.TestField(Quantity, SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,PlanningErrorLogModalPageHandler')]
    [Scope('OnPrem')]
    procedure CalcRegenPlanErrorDoesNotInfluenceRest()
    var
        Item: array[2] of Record Item;
        RoutingHeader: Record "Routing Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Quantity: array[2] of Decimal;
        OrderMultipleQuantity: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Planning]
        // [SCENARIO 230817] When an error occurs on regenerative plan calculation for some item this doesn't cause influence the calculation of other items.
        Initialize();

        OrderMultipleQuantity := LibraryRandom.RandIntInRange(3, 5) * 100;
        Quantity[1] := LibraryRandom.RandIntInRange(3, 5) * 1000 + LibraryRandom.RandInt(OrderMultipleQuantity);
        Quantity[2] := LibraryRandom.RandInt(OrderMultipleQuantity);

        // [GIVEN] Two Items "I1" and "I2", "Replenishment System" = "Prod. Order" both.
        // [GIVEN] "I1" has "Order Multiple" specified, "I1"."Reordering Policy" = "Lot-for-Lot", "I2"."Reordering Policy" = Order.
        // [GIVEN] "I1" is leading when sorting by primary key "No." and has "Routing No." set by uncertified routing "R".
        CreateUncertifiedRouting(RoutingHeader);
        CreateProdOrderItem(Item[1], Item[1]."Reordering Policy"::"Lot-for-Lot", OrderMultipleQuantity, RoutingHeader."No.");
        CreateProdOrderItem(Item[2], Item[2]."Reordering Policy"::Order, 0, '');

        // [GIVEN] Two sales blanket orders "S1" for "I1" and "S2" for "I2" with quantities "Q1" and "Q2".
        for i := 1 to 2 do
            LibrarySales.CreateSalesDocumentWithItem(
              SalesHeader, SalesLine, SalesHeader."Document Type"::"Blanket Order", '', Item[i]."No.", Quantity[i], '', WorkDate());

        // [WHEN] Calculate regenerative plan for "I1" and "I2".
        Item[1].SetFilter("No.", '%1|%2', Item[1]."No.", Item[2]."No.");
        LibraryVariableStorage.Enqueue(ErrorsWhenPlanningMsg); // Enqueue for MessageHandler
        LibraryVariableStorage.Enqueue(Item[1]."No."); // Enqueue for PlanningErrorLogModalPageHandler
        LibraryVariableStorage.Enqueue(StatusMustBeCertifiedErr);
        LibraryVariableStorage.Enqueue(RoutingHeader."No."); // Enqueue for PlanningErrorLogModalPageHandler
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item[1], WorkDate(), WorkDate());

        // [THEN] The message "Not all items were planned." occurs.
        // [THEN] The page "Planning Error Log" opens, it has one line for "I1" with "Error Description" "Status must be equal to 'Certified'  in Routing Header: No.="R". Current value is 'New'."
        // [THEN] The requisition line for "I2" with quantity "Q2" exists.
        FindRequisitionLine(RequisitionLine, Item[2]."No.");
        RequisitionLine.TestField(Quantity, Quantity[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LinesOnOneProdOrderPlannedSeparatelyForItemWithReorderingPolicyOrder()
    var
        CompItem: Record Item;
        ProdItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
        RequisitionLine: Record "Requisition Line";
        Qty: Decimal;
        NoOfLines: Integer;
        i: Integer;
    begin
        // [FEATURE] [Planning] [Reordering Policy] [Production Order] [Prod. Order Component]
        // [SCENARIO 328536] Prod. order components that belong to different prod. order lines in one production order are planned separately for item with Reordering Policy = Order.
        Initialize();
        Qty := LibraryRandom.RandInt(10);
        NoOfLines := LibraryRandom.RandIntInRange(2, 5);

        // [GIVEN] Production item "P".
        // [GIVEN] Component item "C" with Reordering Policy = "Order".
        LibraryInventory.CreateItem(ProdItem);
        LibraryInventory.CreateItem(CompItem);
        CompItem.Validate("Replenishment System", CompItem."Replenishment System"::"Prod. Order");
        CompItem.Validate("Reordering Policy", CompItem."Reordering Policy"::Order);
        CompItem.Modify(true);

        // [GIVEN] Released production order for item "P".
        // [GIVEN] Create 4 prod. order lines, each for 10 pcs.
        // [GIVEN] Add component "C" to each of prod. order lines, "Quantity per" = 10 pcs.
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ProdItem."No.", Qty);
        for i := 1 to NoOfLines do begin
            LibraryManufacturing.CreateProdOrderLine(
              ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.", ProdItem."No.", '', '', Qty);
            LibraryManufacturing.CreateProductionOrderComponent(
              ProdOrderComponent, ProdOrderLine.Status, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.");
            ProdOrderComponent.Validate("Item No.", CompItem."No.");
            ProdOrderComponent.Validate("Quantity per", Qty);
            ProdOrderComponent.Modify(true);
        end;

        // [WHEN] Calculate regenerative plan for item "C".
        CompItem.SetRecFilter();
        LibraryPlanning.CalcRegenPlanForPlanWksh(CompItem, WorkDate(), WorkDate());

        // [THEN] 4 planning lines are created.
        FindRequisitionLine(RequisitionLine, CompItem."No.");
        Assert.RecordCount(RequisitionLine, NoOfLines);

        // [THEN] Each planning line has quantity = 100 (10 pcs on prod. order line * 10 pcs on prod. order component).
        RequisitionLine.SetRange(Quantity, Qty * Qty);
        Assert.RecordCount(RequisitionLine, NoOfLines);

        // [THEN] Each prod. order component line is reserved.
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.FindSet();
        repeat
            ProdOrderComponent.CalcFields("Reserved Quantity");
            ProdOrderComponent.TestField("Reserved Quantity", ProdOrderComponent."Expected Quantity");
        until ProdOrderComponent.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DueDateOnProdOrderLineMatchesOneOnProdOrderHeaderAfterReschedule()
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        SalesLine: Record "Sales Line";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ReschedPeriod: DateFormula;
    begin
        // [FEATURE] [Planning] [Production Order]
        // [SCENARIO 343277] Due Date on prod. order line matches Due Date on production order header after the order is rescheduled by planning.
        Initialize();

        // [GIVEN] Set "Default Safety Lead Time" blank
        LibraryPlanning.SetDefaultSafetyLeadTime('');

        // [GIVEN] Create lot-for-lot item with "Prod. Order" manufacturing policy.
        // [GIVEN] Set rescheduling period on the item so that the planning will reschedule existing supply instead of suggesting "Cancel + New".
        // [GIVEN] Create sales order with "Shipment Date" = WORKDATE.
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);
        CreateWorkCenterDemand(Item, WorkCenter."No.", LibraryRandom.RandIntInRange(50, 100), WorkDate());
        Evaluate(ReschedPeriod, '<2W>');
        Item.Validate("Rescheduling Period", ReschedPeriod);
        Item.Modify(true);

        // [GIVEN] Calculate regenerative plan and carry out action message.
        // [GIVEN] That creates a production order for the item.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate('<-CY>', WorkDate()), CalcDate('<CY>', WorkDate()));
        CarryOutActionMessageOnPlanningWorksheet(Item."No.");

        // [GIVEN] Move the shipment date on the sales order line a week forward.
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetRange("No.", Item."No.");
        SalesLine.FindFirst();
        SalesLine.Validate("Shipment Date", LibraryRandom.RandDate(10));
        SalesLine.Modify(true);

        // [WHEN] Calculate regenerative plan and carry out action message again.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate('<-CY>', WorkDate()), CalcDate('<CY>', WorkDate()));
        CarryOutActionMessageOnPlanningWorksheet(Item."No.");

        // [THEN] A production order is rescheduled.
        // [THEN] New "Due Date" on the header matches "Due Date" on the line.
        // [THEN] "Due Date" is equal to the shipment date on the sales line.
        FindProductionOrder(ProductionOrder, ProductionOrder."Source Type"::Item, Item."No.");
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        ProdOrderLine.TestField("Due Date", ProductionOrder."Due Date");
        ProdOrderLine.TestField("Due Date", SalesLine."Shipment Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StartingEndingDateTimeShouldBeRecalculatedForPlanningRoutingLinesWhenLotSizeChanges()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        Item: Record Item;
        TempOldPlanningRoutingLine: Record "Planning Routing Line" temporary;
        PlanningRoutingLine: Record "Planning Routing Line";
    begin
        // [FEATURE] [Planning] [Planning Routing Line]
        Initialize();

        // [GIVEN] Manufacturing Item "I" with serial routing with 4 lines L1, L2, L3, L4.
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);
        CreateRoutingWithSendahead(RoutingHeader, WorkCenter."No.", 5, 0);
        CreateLotProdMakeToOrderItemWithRoutingNo(Item, RoutingHeader."No.");

        // [GIVEN] Sales Order as Demand for "I".
        CreateSalesOrderWithQuantity(Item."No.", 10);

        // [WHEN] Calculate Regenerative Plan for "I"
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());

        // [THEN] Corresponding data in "Planning Routing Line" table contains 4 Lines;
        PlanningRoutingLine.SetRange("Work Center No.", WorkCenter."No.");
        Assert.RecordCount(PlanningRoutingLine, 4);

        PlanningRoutingLine.FindSet();
        repeat
            TempOldPlanningRoutingLine.Copy(PlanningRoutingLine);
            TempOldPlanningRoutingLine.Insert();
        until PlanningRoutingLine.Next() = 0;

        // [WHEN] Changing the lot size from 1 to 10 for line 2.
        PlanningRoutingLine.FindSet();
        PlanningRoutingLine.Next();
        PlanningRoutingLine.Validate("Lot Size", 10);

        TempOldPlanningRoutingLine.SetRange("Work Center No.", WorkCenter."No.");
        TempOldPlanningRoutingLine.FindSet();
        PlanningRoutingLine.FindSet();

        // [THEN] First line is untouched.
        PlanningRoutingLine.TestField("Starting Date-Time", TempOldPlanningRoutingLine."Starting Date-Time");
        PlanningRoutingLine.TestField("Ending Date-Time", TempOldPlanningRoutingLine."Ending Date-Time");

        PlanningRoutingLine.Next();
        TempOldPlanningRoutingLine.Next();

        // [THEN] Second line is ending earlier.
        PlanningRoutingLine.TestField("Starting Date-Time", TempOldPlanningRoutingLine."Starting Date-Time");
        Assert.IsTrue(PlanningRoutingLine."Ending Date-Time" < TempOldPlanningRoutingLine."Ending Date-Time",
            'Expected new ending date-time to be earlier than original.');

        TempOldPlanningRoutingLine.Next();
        PlanningRoutingLine.Next();

        // [THEN] The rest should have the same time span but start earlier.
        repeat
            Assert.AreEqual(
                PlanningRoutingLine."Ending Date-Time" - PlanningRoutingLine."Starting Date-Time",
                TempOldPlanningRoutingLine."Ending Date-Time" - TempOldPlanningRoutingLine."Starting Date-Time",
                'Expected line to have similar length.'
            );

            Assert.IsTrue(PlanningRoutingLine."Starting Date-Time" < TempOldPlanningRoutingLine."Starting Date-Time",
                'Expected new starting date-time to be earlier than original.');

            Assert.IsTrue(PlanningRoutingLine."Ending Date-Time" < TempOldPlanningRoutingLine."Ending Date-Time",
                'Expected new ending date-time to be earlier than original.');

        until (TempOldPlanningRoutingLine.Next() = 0) and (PlanningRoutingLine.Next() = 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReplanReservedPlanningComponent()
    var
        CompItem: Record Item;
        ProdItem: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ProductionBOMHeader: Record "Production BOM Header";
        RequisitionLine: Record "Requisition Line";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Calculate Regenerative Plan] [Planning Component] [Reservation]
        // [SCENARIO 374378] Calculate regenerative plan sets correct quantity for Prod. Order replenished Item that is partially reserved as another Item's planning component
        Initialize();

        // [GIVEN] Component MTO item "C" with Replenishment by Prod. Order
        // [GIVEN] Production MTO item "P" with Replenishment by Prod. Order, produced from 1 PCS of item "C"
        CreateItemWithReplenishmentSystem(ProdItem, ProdItem."Replenishment System"::"Prod. Order");
        CreateItemWithReplenishmentSystem(CompItem, CompItem."Replenishment System"::"Prod. Order");
        CreateCertifiedProductionBOM(ProductionBOMHeader, CompItem."No.", ProdItem."Base Unit of Measure", 1);
        ProdItem.Validate("Manufacturing Policy", ProdItem."Manufacturing Policy"::"Make-to-Order");
        ProdItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProdItem.Modify(true);
        CompItem.Validate("Manufacturing Policy", CompItem."Manufacturing Policy"::"Make-to-Order");
        CompItem.Modify(true);

        // [GIVEN] Sales Order Line for 10 PCS of Item "P" with "Shipment Date" = 03.03.2022
        CreateSalesOrder(SalesLine, ProdItem."No.", LocationBlue.Code);
        SalesLine.Validate("Shipment Date", LibraryRandom.RandDateFrom(WorkDate() + 10, 10));
        SalesLine.Validate(Quantity, LibraryRandom.RandIntInRange(10, 100));
        SalesLine.Modify(true);

        // [GIVEN] 2 PCS of item "C" in inventory
        LibraryInventory.CreateItemJournalLineInItemTemplate(
          ItemJournalLine, CompItem."No.", LocationBlue.Code, '', LibraryRandom.RandInt(SalesLine.Quantity - 1));
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Calculated regenerative plan for items "C" and "P" from 27.01.2022 to 03.03.2022
        ProdItem.SetFilter("No.", '%1|%2', CompItem."No.", ProdItem."No.");
        LibraryPlanning.CalcRegenPlanForPlanWksh(ProdItem, WorkDate(), SalesLine."Shipment Date");

        // [WHEN] Calculate regenerative plan for item "C" from 27.01.2022 to 03.03.2022
        CompItem.SetRecFilter();
        LibraryPlanning.CalcRegenPlanForPlanWksh(CompItem, WorkDate(), SalesLine."Shipment Date");

        // [THEN] Planning line for Item "C" has quantity = 8
        FindRequisitionLine(RequisitionLine, CompItem."No.");
        RequisitionLine.TestField(Quantity, SalesLine.Quantity - ItemJournalLine.Quantity);
    end;

    [Test]
    procedure TrackingProdOrderComponentByPlanningEngine()
    var
        ProdItem: Record Item;
        CompItem: Record Item;
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ItemJournalLine: Record "Item Journal Line";
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        ReservationEntry: Record "Reservation Entry";
        ReschedulingPeriod: DateFormula;
    begin
        // [FEATURE] [Planning] [Prod. Order Component]
        // [SCENARIO 386704] The planning engine establishes tracking between Prod. Order Component in a released production order and inventory.
        Initialize();

        // [GIVEN] Component item "C" set up for lot-for-lot planning.
        // [GIVEN] Production BOM with component "C".
        LibraryInventory.CreateItem(CompItem);
        CompItem.Validate("Reordering Policy", CompItem."Reordering Policy"::"Lot-for-Lot");
        CompItem.Modify(true);
        CreateCertifiedProductionBOM(ProductionBOMHeader, CompItem."No.", CompItem."Base Unit of Measure", 1);

        // [GIVEN] Production item "P" set up for lot-for-lot planning.
        // [GIVEN] Enable rescheduling on the item "P".
        // [GIVEN] Assign the production BOM.
        Evaluate(ReschedulingPeriod, '<1M>');
        CreateItemWithReplenishmentSystem(ProdItem, ProdItem."Replenishment System"::"Prod. Order");
        ProdItem.Validate("Reordering Policy", ProdItem."Reordering Policy"::"Lot-for-Lot");
        ProdItem.Validate("Rescheduling Period", ReschedulingPeriod);
        ProdItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProdItem.Modify(true);

        // [GIVEN] Post 50 pcs of item "C" to inventory.
        LibraryInventory.CreateItemJournalLineInItemTemplate(
          ItemJournalLine, CompItem."No.", '', '', LibraryRandom.RandIntInRange(50, 100));
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Create and refresh released production order for 10 pcs of item "P" on "WorkDate() + 10 days".
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ProdItem."No.",
          LibraryRandom.RandIntInRange(10, 20));
        ProductionOrder.SetUpdateEndDate();
        ProductionOrder.Validate("Due Date", LibraryRandom.RandDate(10));
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        FindProdOrderComponent(ProdOrderComponent, ProductionOrder."No.", CompItem."No.");

        // [GIVEN] Create sales order for 10 pcs of item "P" on WORKDATE.
        CreateSalesOrderWithQuantity(ProdItem."No.", ProductionOrder.Quantity);

        // [WHEN] Calculate regenerative plan for both items "C" and "P".
        Item.SetFilter("No.", '%1|%2', CompItem."No.", ProdItem."No.");
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate('<-CY>', WorkDate()), CalcDate('<CY>', WorkDate()));

        // [THEN] Prod. order component "C" of the released production order becomes tracked from the inventory.
        ReservationEntry.SetSourceFilter(
          DATABASE::"Prod. Order Component", ProdOrderComponent.Status.AsInteger(), ProdOrderComponent."Prod. Order No.",
          ProdOrderComponent."Line No.", true);
        ReservationEntry.FindFirst();
        ReservationEntry.Get(ReservationEntry."Entry No.", not ReservationEntry.Positive);
        ReservationEntry.TestField("Source Type", DATABASE::"Item Ledger Entry");
    end;

    [Test]
    procedure RescheduleLowerLevelItemInMakeToOrderProductionOrder()
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        DummyItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        ReschedulingPeriod: DateFormula;
    begin
        // [FEATURE] [Planning] [Production Order] [Make-to-Order]
        // [SCENARIO 407546] Lower-level item in make-to-order (MTO) production order is rescheduled together with the final item.
        Initialize();
        Evaluate(ReschedulingPeriod, '<2W>');

        // [GIVEN] Lot-for-lot intermediate item "C" with Make-to-Order manufacturing policy and rescheduling period 2 weeks.
        CreateLotProdMakeToOrderItemWithRoutingNo(ChildItem, '');
        ChildItem.Validate("Rescheduling Period", ReschedulingPeriod);
        ChildItem.Modify(true);

        // [GIVEN] Production BOM with component item "C".
        CreateCertifiedProductionBOM(ProductionBOMHeader, ChildItem."No.", ChildItem."Base Unit of Measure", 1);

        // [GIVEN] Lot-for-lot final product "F" with Make-to-Order manufacturing policy and rescheduling period 2 weeks.
        // [GIVEN] Add the production BOM to the item "F".
        CreateLotProdMakeToOrderItemWithRoutingNo(ParentItem, '');
        ParentItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ParentItem.Validate("Rescheduling Period", ReschedulingPeriod);
        ParentItem.Modify(true);

        // [GIVEN] Sales order for item "F".
        CreateSalesOrder(SalesLine, ParentItem."No.", '');

        // [GIVEN] Calculate regenerative plan and carry out action message for items "F" and "C".
        DummyItem.SetFilter("No.", '%1|%2', ParentItem."No.", ChildItem."No.");
        LibraryPlanning.CalcRegenPlanForPlanWksh(DummyItem, CalcDate('<-CY>', WorkDate()), CalcDate('<CY>', WorkDate()));
        CarryOutActionMessageOnPlanningWorksheet(ParentItem."No.");
        CarryOutActionMessageOnPlanningWorksheet(ChildItem."No.");

        // [GIVEN] Reschedule the sales order - set Shipment Date one week later.
        SalesLine.Find();
        SalesLine.Validate("Shipment Date", CalcDate('<1W>', SalesLine."Shipment Date"));
        SalesLine.Modify(true);

        // [WHEN] Calculate regenerative plan for items "F" and "C" again.
        LibraryPlanning.CalcRegenPlanForPlanWksh(DummyItem, CalcDate('<-CY>', WorkDate()), CalcDate('<CY>', WorkDate()));

        // [THEN] Two planning lines for both final and intermediate items are created.
        FindRequisitionLine(RequisitionLine, ParentItem."No.");
        RequisitionLine.TestField("Action Message", RequisitionLine."Action Message"::Reschedule);
        RequisitionLine.TestField("Planning Level", 0);
        FindRequisitionLine(RequisitionLine, ChildItem."No.");
        RequisitionLine.TestField("Action Message", RequisitionLine."Action Message"::Reschedule);
        RequisitionLine.TestField("Planning Level", 1);
    end;

    [Test]
    [HandlerFunctions('PlanningErrorLogModalPageHandler,MessageHandler')]
    procedure CheckNestedBOMIsCertifiedOnAddingPlanningComponent()
    var
        Item: Record Item;
        NestedProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMHeader: Record "Production BOM Header";
        RequisitionLine: Record "Requisition Line";
    begin
        // [FEATURE] [Planning Component] [Production BOM]
        // [SCENARIO 412566] Check that nested production BOM is certified when adding a planning component.
        Initialize();

        // [GIVEN] Manufacturing item "I" set up for planning.
        CreateFixedReorderQtyItemWithRoutingNo(Item, '');

        // [GIVEN] Production BOM "A" in "Under Development" status with some component item.
        // [GIVEN] Production BOM "B" in "Certified" status with the production BOM "A" as component.
        CreateCertifiedProductionBOM(NestedProductionBOMHeader, LibraryInventory.CreateItemNo(), Item."Base Unit of Measure", 1);
        LibraryManufacturing.UpdateProductionBOMStatus(NestedProductionBOMHeader, NestedProductionBOMHeader.Status::"Under Development");
        CreateProductionBOMWithProdBOMAsComponent(ProductionBOMHeader, NestedProductionBOMHeader."No.", Item."Base Unit of Measure", 1);

        // [GIVEN] Set Production BOM No. = "B" on item "I".
        Item.Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item.Modify(true);

        // [WHEN] Calculate regenerative plan for "I".
        Item.SetRecFilter();
        LibraryVariableStorage.Enqueue(ErrorsWhenPlanningMsg);
        LibraryVariableStorage.Enqueue(Item."No.");
        LibraryVariableStorage.Enqueue(ProdBOMMustBeCertifiedErr);
        LibraryVariableStorage.Enqueue(NestedProductionBOMHeader."No.");
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());

        // [THEN] A planning line is not created.
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", Item."No.");
        Assert.RecordIsEmpty(RequisitionLine);

        // [THEN] "Status must be equal to 'Certified'" message in the planning error log.

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure ComponentsAtLocationAtSKULevelConsideredForForecastWithLocationMandatory()
    var
        Location: Record Location;
        ProdItem: Record Item;
        CompItem: Record Item;
        Item: Record Item;
        SKU: Record "Stockkeeping Unit";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionForecastName: Record "Production Forecast Name";
        ProductionForecastEntry: Record "Production Forecast Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        PlanningErrorLog: Record "Planning Error Log";
    begin
        // [FEATURE] [Planning] [Stockkeeping Unit] [Production Forecast]
        // [SCENARIO 433269] "Components at Location" at stockkeeping unit level must be considered for planning demand forecast.
        Initialize();
        PlanningErrorLog.DeleteAll();

        // [GIVEN] Location is mandatory.
        LibraryInventory.SetLocationMandatory(true);

        // [GIVEN] Location "L".
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Component item "C", create stockkeeping unit, set up "Components at Location" = "L" in the SKU.
        CreateItemWithReplenishmentSystem(CompItem, CompItem."Replenishment System"::Purchase);
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(SKU, Location.Code, CompItem."No.", '');
        SKU.Validate("Components at Location", Location.Code);
        SKU.Modify(true);

        // [GIVEN] Finished item "P", create production BOM, quantity per = 1.
        CreateCertifiedProductionBOM(ProductionBOMHeader, CompItem."No.", CompItem."Base Unit of Measure", 1);
        CreateItemWithReplenishmentSystem(ProdItem, ProdItem."Replenishment System"::"Prod. Order");
        ProdItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProdItem.Modify(true);

        // [GIVEN] Component forecast for item "C", forecast quantity = 1000.
        LibraryManufacturing.CreateProductionForecastName(ProductionForecastName);
        CreateProductionForecastEntryWithBlankLocation(ProductionForecastEntry, CompItem, ProductionForecastName.Name, true);
        ProductionForecastEntry.Validate("Location Code", Location.Code);
        ProductionForecastEntry.Modify(true);

        // [GIVEN] Clear "Components at Location"
        UpdateCurrentDemandForecastAndComponentsAtLocation(ProductionForecastName.Name, '');
        UpdateUseForecastOnLocationsInManufacturingSetup(true);

        // [GIVEN] Sales order for 100 pcs of item "P". This is the demand for planning.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '',
          ProdItem."No.", LibraryRandom.RandIntInRange(50, 100), Location.Code, WorkDate() + 90);

        // [WHEN] Calculate regenerative plan for items "P" and "C".
        Item.SetFilter("No.", '%1|%2', ProdItem."No.", CompItem."No.");
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), CalcDate('<CY>', ProductionForecastEntry."Forecast Date"));

        // [THEN] 100 pcs of component "C" are planned to address the sales order.
        FindRequisitionLine(RequisitionLine, CompItem."No.");
        RequisitionLine.SetRange("MPS Order", false);
        RequisitionLine.CalcSums(Quantity);
        RequisitionLine.TestField(Quantity, SalesLine.Quantity);

        // [THEN] 900 pcs of component "C" are planned to address the forecast.
        RequisitionLine.SetRange("MPS Order", true);
        RequisitionLine.CalcSums(Quantity);
        RequisitionLine.TestField(Quantity, ProductionForecastEntry."Forecast Quantity" - SalesLine.Quantity);
    end;

    [Test]
    procedure SecondPlanningRunForMakeToOrderProductionOrder()
    var
        FinalItem: Record Item;
        SemiItem: Record Item;
        CompItem: Record Item;
        PlanningItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        RequisitionLine: Record "Requisition Line";
    begin
        // [FEATURE] [Planning] [Planning Component] [Make-to-Order]
        // [SCENARIO 437740] No error on the second planning run for make-to-order production order.
        Initialize();

        // [GIVEN] Component item.
        LibraryInventory.CreateItem(CompItem);

        // [GIVEN] Semi-production item with Make-to-Order manufacturing policy.
        LibraryInventory.CreateItem(SemiItem);
        SemiItem.Validate("Replenishment System", SemiItem."Replenishment System"::"Prod. Order");
        SemiItem.Validate("Manufacturing Policy", SemiItem."Manufacturing Policy"::"Make-to-Order");
        SemiItem.Validate("Reordering Policy", SemiItem."Reordering Policy"::"Lot-for-Lot");
        SemiItem.Modify(true);

        // [GIVEN] Create production BOM containing both the component item and the semi-production item.
        LibraryManufacturing.CreateCertifProdBOMWithTwoComp(ProductionBOMHeader, CompItem."No.", SemiItem."No.", 1);

        // [GIVEN] Finished item with Make-to-Order manufacturing policy.
        LibraryInventory.CreateItem(FinalItem);
        FinalItem.Validate("Replenishment System", SemiItem."Replenishment System"::"Prod. Order");
        FinalItem.Validate("Manufacturing Policy", SemiItem."Manufacturing Policy"::"Make-to-Order");
        FinalItem.Validate("Reordering Policy", SemiItem."Reordering Policy"::"Maximum Qty.");
        FinalItem.Validate("Maximum Inventory", LibraryRandom.RandIntInRange(50, 100));
        FinalItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        FinalItem.Modify(true);

        // [GIVEN] Calculate regenerative plan for all new items.
        PlanningItem.SetFilter("No.", '%1|%2|%3', CompItem."No.", SemiItem."No.", FinalItem."No.");
        LibraryPlanning.CalcRegenPlanForPlanWksh(PlanningItem, WorkDate(), CalcDate('<CY>', WorkDate()));

        // [GIVEN] Carry out action message to create make-to-order production order and a purchase order.
        PlanningItem.CopyFilter("No.", RequisitionLine."No.");
        RequisitionLine.FindSet();
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);

        // [WHEN] Calculate regenerative plan again.
        LibraryPlanning.CalcRegenPlanForPlanWksh(PlanningItem, WorkDate(), CalcDate('<CY>', WorkDate()));

        // [THEN] No errors occured during planning.
        // [THEN] No planning lines created.
        RequisitionLine.Reset();
        PlanningItem.CopyFilter("No.", RequisitionLine."No.");
        Assert.RecordIsEmpty(RequisitionLine);
    end;

    [Test]
    procedure ForecastOnVariantsInPlanning()
    var
        Item: Record Item;
        Location: array[2] of Record Location;
        ItemVariant: array[2] of Record "Item Variant";
        ProductionForecastName: Record "Production Forecast Name";
        Qty: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Item Variant] [Demand Forecast]
        // [SCENARIO 458828] Correct planning result of demand forecast by variants.
        Initialize();
        Qty := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Set "Use Forecast on Variants" = TRUE and "Use Forecast on Locations" = FALSE
        UpdateUseForecastOnVariantsInManufacturingSetup(true);
        UpdateUseForecastOnLocationsInManufacturingSetup(false);

        // [GIVEN] Planning item.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::Order);
        Item.Modify(true);

        // [GIVEN] 2 locations and 2 variants//, create 4 stockkeeping units.
        for i := 1 to ArrayLen(Location) do
            LibraryWarehouse.CreateLocation(Location[i]);
        for i := 1 to ArrayLen(ItemVariant) do
            LibraryInventory.CreateItemVariant(ItemVariant[i], Item."No.");

        // [GIVEN] Create demand forecast:
        // [GIVEN] Variant 1 in January, Variant 2 in February, Variant 1 in March for each location.
        LibraryManufacturing.CreateProductionForecastName(ProductionForecastName);
        CreateProductionForecastEntry(ProductionForecastName.Name, Item, Location[1].Code, ItemVariant[1].Code, WorkDate(), Qty);
        CreateProductionForecastEntry(ProductionForecastName.Name, Item, Location[1].Code, ItemVariant[1].Code, WorkDate() + 60, Qty);
        CreateProductionForecastEntry(ProductionForecastName.Name, Item, Location[1].Code, ItemVariant[2].Code, WorkDate() + 30, Qty);
        CreateProductionForecastEntry(ProductionForecastName.Name, Item, Location[2].Code, ItemVariant[1].Code, WorkDate(), Qty);
        CreateProductionForecastEntry(ProductionForecastName.Name, Item, Location[2].Code, ItemVariant[1].Code, WorkDate() + 60, Qty);
        CreateProductionForecastEntry(ProductionForecastName.Name, Item, Location[2].Code, ItemVariant[2].Code, WorkDate() + 30, Qty);

        // [GIVEN] Select this forecast
        UpdateCurrentDemandForecastAndComponentsAtLocation(ProductionForecastName.Name, '');

        // [WHEN] Calculate regenerative plan for the item.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate('<-CY>', WorkDate()), CalcDate('<CY>', WorkDate()));

        // [THEN] Demand forecast is properly planned - two supplies suggested for Variant 1 and one for Variant 2.
        VerifyRequisitionLineCountAndQty(Item."No.", ItemVariant[1].Code, 2, 4 * Qty);
        VerifyRequisitionLineCountAndQty(Item."No.", ItemVariant[2].Code, 1, 2 * Qty);
    end;

    [Test]
    procedure ForecastOnVariantsAndLocationsInPlanning()
    var
        Item: Record Item;
        Location: array[2] of Record Location;
        ItemVariant: array[2] of Record "Item Variant";
        ProductionForecastName: Record "Production Forecast Name";
        Qty: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Item Variant] [Demand Forecast]
        // [SCENARIO 458828] Correct planning result of demand forecast by variants and locations.
        Initialize();
        Qty := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Set "Use Forecast on Variants" = TRUE and "Use Forecast on Locations" = TRUE
        UpdateUseForecastOnVariantsInManufacturingSetup(true);
        UpdateUseForecastOnLocationsInManufacturingSetup(true);

        // [GIVEN] Planning item.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::Order);
        Item.Modify(true);

        // [GIVEN] 2 locations and 2 variants, create 4 stockkeeping units.
        for i := 1 to ArrayLen(Location) do
            LibraryWarehouse.CreateLocation(Location[i]);
        for i := 1 to ArrayLen(ItemVariant) do
            LibraryInventory.CreateItemVariant(ItemVariant[i], Item."No.");

        // [GIVEN] Create demand forecast:
        // [GIVEN] Variant 1 in January, Variant 2 in February, Variant 1 in March for each location.
        LibraryManufacturing.CreateProductionForecastName(ProductionForecastName);
        CreateProductionForecastEntry(ProductionForecastName.Name, Item, Location[1].Code, ItemVariant[1].Code, WorkDate(), Qty);
        CreateProductionForecastEntry(ProductionForecastName.Name, Item, Location[1].Code, ItemVariant[1].Code, WorkDate() + 60, Qty);
        CreateProductionForecastEntry(ProductionForecastName.Name, Item, Location[1].Code, ItemVariant[2].Code, WorkDate() + 30, Qty);
        CreateProductionForecastEntry(ProductionForecastName.Name, Item, Location[2].Code, ItemVariant[1].Code, WorkDate(), Qty);
        CreateProductionForecastEntry(ProductionForecastName.Name, Item, Location[2].Code, ItemVariant[1].Code, WorkDate() + 60, Qty);
        CreateProductionForecastEntry(ProductionForecastName.Name, Item, Location[2].Code, ItemVariant[2].Code, WorkDate() + 30, Qty);

        // [GIVEN] Select this forecast
        UpdateCurrentDemandForecastAndComponentsAtLocation(ProductionForecastName.Name, '');

        // [WHEN] Calculate regenerative plan for the item.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate('<-CY>', WorkDate()), CalcDate('<CY>', WorkDate()));

        // [THEN] Demand forecast is properly planned - two supplies suggested for Variant 1 and one for Variant 2 for each location.
        VerifyRequisitionLineCountAndQty(Item."No.", ItemVariant[1].Code, 4, 4 * Qty);
        VerifyRequisitionLineCountAndQty(Item."No.", ItemVariant[2].Code, 2, 2 * Qty);
    end;

    [Test]
    procedure VerifyBinCodesOnPlanningComponentsForComponentsWithRoutingLinkCode()
    var
        ParentItem: Record Item;
        LocationSilver: Record Location;
        WorkCenter: Record "Work Center";
        ComponentItems: array[3] of Record Item;
        RoutingLinks: array[2] of Record "Routing Link";
        Bins: array[5] of Record Bin;
        MachineCenters: array[2] of Record "Machine Center";
    begin
        // [SCENARIO 461527] Verify Bin Codes on Planning Components are pulled from Machine Centers, when we have Routing Link Code
        Initialize();

        // [GIVEN] Location Silver with Require Put-away, Require Pick and Bin Mandatory
        CreateAndUpdateLocation(LocationSilver, true, true, false, false, true);

        // [GIVEN] Create Bins on Location
        CreateBinsOnLocation(Bins, LocationSilver);

        // [GIVEN] Add Silver Location
        LibraryManufacturing.SetComponentsAtLocation(LocationSilver.Code);

        // [GIVEN] Work center with Location
        CreateWorkCenterWithLocation(WorkCenter, LocationSilver.Code);

        // [GIVEN] Machine Centers
        CreateMachineCentersWithBins(MachineCenters, WorkCenter, Bins);

        // [GIVEN] Create Item with  Replenishment System = Prod. Order, Manufacturing Policy = Make-to-Order, Reordering Policy = Lot-for-Lot
        CreateLotProdMakeToOrderItemWithRoutingNo(ParentItem, '');

        // [GIVEN] Create Component Items
        CreateComponentItems(ComponentItems);

        // [GIVEN] Create Routing Links
        CreateRoutingLinks(RoutingLinks);

        // [GIVEN] Create Prod. BOM with Component Items
        CreateAndCertifyProdBOMWithMultipleComponents(ParentItem, ComponentItems, RoutingLinks);

        // [GIVEN] Create Routing and assign to Item
        CreateRouting(ParentItem, WorkCenter, MachineCenters, RoutingLinks);

        // [GIVEN] Create and Post Purchase Order
        CreateAndPostPurchaseOrderWithBin(ComponentItems, Bins[5].Code, LocationSilver.Code);

        // [GIVEN] Create and Release Sales Order for Parent Item
        CreateAndReleaseSalesOrder(ParentItem."No.", LocationSilver.Code);

        // [WHEN] Calculate regenerative plan for the item.
        LibraryPlanning.CalcRegenPlanForPlanWksh(ParentItem, CalcDate('<-CY>', WorkDate()), CalcDate('<CY>', WorkDate()));

        // [THEN] Verify Bin Code On Planning Component
        VerifyBinCodeOnPlanningComponent(ComponentItems[1], Bins[2].Code);
        VerifyBinCodeOnPlanningComponent(ComponentItems[2], Bins[2].Code);
        VerifyBinCodeOnPlanningComponent(ComponentItems[3], Bins[4].Code);
    end;

    [Test]
    procedure VerifyStartingTimeInRoutingWithSendAheadQtyOnReleasedProductionOrder()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
    begin
        // [SCENARIO 471307] Verify Starting Time in Routing with Send Ahead Qty. on Released Production Order
        Initialize();

        // [GIVEN] Create Work Center with Calendar
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);

        // [GIVEN] Create Routing with Send Ahead
        CreateRoutingWithSendahead(RoutingHeader, WorkCenter."No.", 1, 1, 1, 1, 2);

        // [GIVEN] Create Prod. Order Item with Routing No.
        CreateLotProdMakeToOrderItemWithRoutingNo(Item, RoutingHeader."No.");

        // [WHEN] Create and Release Production Order
        CreateAndRefreshReleasedProductionOrderWithQty(ProductionOrder, Item."No.", 10);

        // [THEN] Verify Results
        VefiryTimeBetweenOperations(ProductionOrder."No.");
    end;

    [Test]
    [HandlerFunctions('SimpleMessageHandler')]
    [Scope('OnPrem')]
    procedure VerifyAssemblyOrderIsCreatedForBothItemsUsingGetActionMessage()
    var
        CompItem, ParentItem, ChildItem : Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        BOMComponent: Record "BOM Component";
        RequisitionLine: Record "Requisition Line";
        AssemblyHeader: Record "Assembly Header";
    begin
        // [SCENARIO 491334] Verify the assembly order is created for both items using "Get Action Message."
        Initialize();

        // [GIVEN] Create a component item.
        LibraryInventory.CreateItem(CompItem);

        // [GIVEN] Create a child item.
        CreateItemWithOrderTrackingPolicy(ChildItem, "Order Tracking Policy"::"Tracking & Action Msg.");

        // [GIVEN] Create a parent item.
        CreateItemWithOrderTrackingPolicy(ParentItem, "Order Tracking Policy"::"Tracking & Action Msg.");

        // [GIVEN] Create a BOM component for the child item.
        LibraryInventory.CreateBOMComponent(
            BOMComponent, ChildItem."No.", BOMComponent.Type::Item,
            CompItem."No.", LibraryRandom.RandIntInRange(1, 1), '');

        // [GIVEN] Create a BOM component for the parent item.
        LibraryInventory.CreateBOMComponent(
            BOMComponent, ParentItem."No.", BOMComponent.Type::Item,
            ChildItem."No.", LibraryRandom.RandIntInRange(1, 1), '');

        // [GIVEN] Create a purchase order for the parent item.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ParentItem."No.", LibraryRandom.RandInt(10));

        // [GIVEN] Perform "Get Action Message" for the parent item.
        LibraryPlanning.GetActionMessages(ParentItem);

        // [GIVEN] Find Requisition Line for the parent item.
        RequisitionLine.SetRange("No.", ParentItem."No.");
        RequisitionLine.FindFirst();

        // [GIVEN] Save a transaction.
        Commit();

        // [GIVEN] Create an assembly order for the parent item.
        RunRequisitionCarryOutReportAssemblyOrder(RequisitionLine);

        // [WHEN] Perform "Get Action Message" for the child item.
        LibraryPlanning.GetActionMessages(ChildItem);

        // [GIVEN] Find Requisition Line for the child item.
        RequisitionLine.SetRange("No.", ChildItem."No.");
        RequisitionLine.FindFirst();

        // [GIVEN] Save a transaction.
        Commit();

        // [WHEN] Create an assembly order for the child item.
        RunRequisitionCarryOutReportAssemblyOrder(RequisitionLine);

        // [Verify] Verify the assembly order is created for both items.
        AssemblyHeader.SetFilter("Item No.", '%1|%2', ParentItem."No.", ChildItem."No.");
        Assert.RecordCount(AssemblyHeader, 2);
    end;

    [Test]
    procedure ForecastInPlanningHasMultipleSKU()
    var
        Item: Record Item;
        Location: array[2] of Record Location;
        ProductionForecastName: Record "Production Forecast Name";
        StockkeepingUnit: Record "Stockkeeping Unit";
        Qty: Decimal;
        i: Integer;
    begin
        // [SCENARIO 547123] Correct planning result of demand forecast that has multiple SKU.
        Initialize();

        // [GIVEN] Generate a Quantity and save it in a Variable.
        Qty := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Set "Use Forecast on Locations" = TRUE
        UpdateUseForecastOnLocationsInManufacturingSetup(true);

        // [GIVEN] Set Location Mandatory = TRUE in Inventory Setup.
        LibraryInventory.SetLocationMandatory(true);

        // [GIVEN] Create a Item and Validate Reordering Policy.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Item.Modify(true);

        // [GIVEN] Create two Locations and two Stock Keeping Unit.
        for i := 1 to ArrayLen(Location) do begin
            LibraryWarehouse.CreateLocation(Location[i]);
            LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, Location[i].Code, Item."No.", '');
            StockkeepingUnit.Validate("Include Inventory", false);
            StockkeepingUnit.Modify(true);
        end;

        // [GIVEN] Create a Demand Forecast.        
        LibraryManufacturing.CreateProductionForecastName(ProductionForecastName);

        // [GIVEN] Create a Forecast Entry.
        CreateProductionForecastEntryWithComponent(ProductionForecastName.Name, Item, Location[1].Code, '', WorkDate(), Qty);

        // [GIVEN] Update with Current Production Forecast Name
        UpdateCurrentDemandForecastAndComponentsAtLocation(ProductionForecastName.Name, '');

        // [WHEN] Calculate Plan for Requisition WorkSheet.
        CalcRequisitionPlanForReqWkshWithMfg(Item, CalcDate('<-CY>', WorkDate()), CalcDate('<CY>', WorkDate()));

        // [THEN] Demand forecast is properly planned with One Item line and Quanity.
        VerifyRequisitionLineCountAndQty(Item."No.", '', 1, Qty);
    end;

    [Test]
    procedure OrderTrackDataIsCorrectlyRebuiltWhenChangeQuantityActionIsCarriedOut()
    var
        Item: Record Item;
        Location: Record Location;
        PurchaseLine: Record "Purchase Line";
        SalesLine: array[2] of Record "Sales Line";
        StockkeepingUnit: Record "Stockkeeping Unit";
        Vendor: Record Vendor;
        ReplenishmentSystem: Enum "Replenishment System";
        i: Integer;
        Quantity: array[2] of Decimal;
    begin
        // [SCENARIO 549590] Order Tracking Page shows correct number of tracked lines as in sequence of action
        // When Change Quantity Action is carried out.
        Initialize();

        // [GIVEN] Location is mandatory.
        LibraryInventory.SetLocationMandatory(true);

        // [GIVEN] Generate Quantities and save it in a Variable.
        Quantity[1] := LibraryRandom.RandInt(0);
        Quantity[2] := LibraryRandom.RandIntInRange(1, 5);

        // [GIVEN] Create Vendor.
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Create Item and Validate Vendor No.
        CreateItemWithReplenishmentSystem(Item, ReplenishmentSystem::Purchase);
        Item.Validate("Vendor No.", Vendor."No.");
        Item.Modify(true);

        // [GIVEN] Create Location.
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] Create Stock Keeping Unit.
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, Location.Code, Item."No.", '');

        // [GIVEN] Create Sales Order and Calculate Regenerative Plan.
        for i := 1 to 2 do begin
            CreateSalesOrderWithQuantityAndLocation(SalesLine[i], Item."No.", Location.Code, Quantity[i]);
            LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());
            CarryOutActionMessageOnPlanningWorksheet(Item."No.");
        end;

        // [WHEN] Find Purchase Line for the Item
        FindPurchaseLine(PurchaseLine, Item."No.");

        // [THEN] Verify Fields "Total Quantity", "Item No.", "Quantity" of Order Tracking.
        VerifyOrderTracking(PurchaseLine, Quantity[1] + Quantity[2], Quantity, Item."No.")
    end;

    local procedure Initialize()
    var
        PlanningErrorLog: Record "Planning Error Log";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Planning And Manufacturing");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        LibraryApplicationArea.EnablePremiumSetup();

        PlanningErrorLog.DeleteAll();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Planning And Manufacturing");
        NoSeriesSetup();
        OutputJournalSetup();
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationBlue);
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        isInitialized := true;
        Commit();

        LibrarySetupStorage.SaveManufacturingSetup();
        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Planning And Manufacturing");
    end;

    local procedure SalesForecastWithBlankLocationCodeForAssemblyProdOrderItemWhenComponentsAtLocation(ReplenishmentSystem: Enum "Replenishment System")
    var
        Location: Record Location;
        Item: Record Item;
        ProductionForecastName: Record "Production Forecast Name";
        ProductionForecastEntry: Record "Production Forecast Entry";
        RequisitionLine: Record "Requisition Line";
    begin
        Initialize();
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        CreateItemWithReplenishmentSystem(Item, ReplenishmentSystem);
        LibraryManufacturing.CreateProductionForecastName(ProductionForecastName);
        UpdateCurrentDemandForecastAndComponentsAtLocation(ProductionForecastName.Name, Location.Code);

        CreateProductionForecastEntryWithBlankLocation(ProductionForecastEntry, Item, ProductionForecastName.Name, false);

        IncreaseItemInventoryAtLocation(Location.Code, Item."No.");

        LibraryPlanning.CalcRegenPlanForPlanWkshPlanningParams(
          Item, WorkDate(), CalcDate('<CY>', ProductionForecastEntry."Forecast Date"), true);

        FindRequisitionLine(RequisitionLine, Item."No.");
        Assert.RecordCount(RequisitionLine, 1);
        RequisitionLine.TestField(Quantity, ProductionForecastEntry."Forecast Quantity");
        RequisitionLine.TestField("Location Code", '');
    end;

    local procedure ComponentForecastWithBlankLocationCodeForAssemblyProdOrderItemWhenComponentsAtLocation(ReplenishmentSystem: Enum "Replenishment System")
    var
        Location: Record Location;
        Item: Record Item;
        ProductionForecastName: Record "Production Forecast Name";
        ProductionForecastEntry: Record "Production Forecast Entry";
        RequisitionLine: Record "Requisition Line";
        ItemInventory: Decimal;
    begin
        Initialize();
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        CreateItemWithReplenishmentSystem(Item, ReplenishmentSystem);
        LibraryManufacturing.CreateProductionForecastName(ProductionForecastName);
        UpdateCurrentDemandForecastAndComponentsAtLocation(ProductionForecastName.Name, Location.Code);

        CreateProductionForecastEntryWithBlankLocation(ProductionForecastEntry, Item, ProductionForecastName.Name, true);

        ItemInventory := IncreaseItemInventoryAtLocation(Location.Code, Item."No.");

        LibraryPlanning.CalcRegenPlanForPlanWkshPlanningParams(
          Item, WorkDate(), CalcDate('<CY>', ProductionForecastEntry."Forecast Date"), true);

        FindRequisitionLine(RequisitionLine, Item."No.");
        Assert.RecordCount(RequisitionLine, 1);
        RequisitionLine.TestField(Quantity, ProductionForecastEntry."Forecast Quantity" - ItemInventory);
        RequisitionLine.TestField("Location Code", Location.Code);
    end;

    local procedure NoSeriesSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Modify(true);

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure OutputJournalSetup()
    begin
        Clear(OutputItemJournalTemplate);
        OutputItemJournalTemplate.Init();
        LibraryInventory.SelectItemJournalTemplateName(OutputItemJournalTemplate, OutputItemJournalTemplate.Type::Output);
        OutputItemJournalTemplate.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        OutputItemJournalTemplate.Modify(true);

        Clear(OutputItemJournalBatch);
        OutputItemJournalBatch.Init();
        LibraryInventory.SelectItemJournalBatchName(
          OutputItemJournalBatch, OutputItemJournalTemplate.Type, OutputItemJournalTemplate.Name);
        OutputItemJournalBatch.Modify(true);
    end;

    local procedure AddLotItemTrackingToOutputJournalLine(var ItemJournalLine: Record "Item Journal Line"; ProductionOrder: Record "Production Order") LotNo: Code[50]
    begin
        LotNo := LibraryUtility.GenerateGUID();
        LibraryVariableStorage.Enqueue(LotNo);  // Enqueue for ItemTrackingLinesPageHandler.
        FindOutputJournalLine(ItemJournalLine, ProductionOrder, '', ItemJournalLine.Type, '');
        ItemJournalLine.OpenItemTrackingLines(false);
    end;

    local procedure CreateAbscenceShipmentPlanningFromToDatesSetup(var AbsenceDate: Date; var ShipmentDate: Date; var PlanningFromDate: Date; var PlanningToDate: Date)
    var
        CMDateFormula: DateFormula;
    begin
        PlanningFromDate := WorkDate();
        AbsenceDate := LibraryRandom.RandDateFrom(PlanningFromDate, LibraryRandom.RandInt(10));
        ShipmentDate := AbsenceDate + 1;
        Evaluate(CMDateFormula, '<CM>');
        PlanningToDate := CalcDate(CMDateFormula, ShipmentDate);
    end;

    local procedure CreateShipmentPlanningFromToDatesSetup(var ShipmentDate: Date; var PlanningFromDate: Date; var PlanningToDate: Date)
    var
        CMDateFormula: DateFormula;
    begin
        PlanningFromDate := WorkDate();
        ShipmentDate := PlanningFromDate + LibraryRandom.RandInt(10);
        Evaluate(CMDateFormula, '<CM>');
        PlanningToDate := CalcDate(CMDateFormula, ShipmentDate);
    end;

    local procedure WorkCenterAndDemandAbsenceBeginningDay(var Item: Record Item; var WorkCenterNo: Code[20]; var ShipmentDate: Date; var PlanningFromDate: Date; var PlanningToDate: Date; RunTime: Integer; TimeShift: Boolean)
    var
        WorkCenter: Record "Work Center";
        AbsenceDate: Date;
    begin
        CreateAbscenceShipmentPlanningFromToDatesSetup(AbsenceDate, ShipmentDate, PlanningFromDate, PlanningToDate);
        CreateWorkCenterWithAbsenceInTheBeginningOfDay(WorkCenter, AbsenceDate, PlanningFromDate, PlanningToDate, TimeShift);
        CreateWorkCenterDemand(Item, WorkCenter."No.", RunTime, ShipmentDate);
        WorkCenterNo := WorkCenter."No.";
    end;

    local procedure WorkCenterAndDemandAbsenceMiddleDay(var Item: Record Item; var WorkCenterNo: Code[20]; var ShipmentDate: Date; var PlanningFromDate: Date; var PlanningToDate: Date; RunTime: Integer)
    var
        WorkCenter: Record "Work Center";
        AbsenceDate: Date;
    begin
        CreateAbscenceShipmentPlanningFromToDatesSetup(AbsenceDate, ShipmentDate, PlanningFromDate, PlanningToDate);
        CreateWorkCenterWithAbsenceInTheMiddleOfDay(WorkCenter, AbsenceDate, PlanningFromDate, PlanningToDate);
        CreateWorkCenterDemand(Item, WorkCenter."No.", RunTime, ShipmentDate);
        WorkCenterNo := WorkCenter."No.";
    end;

    local procedure WorkCenterAndDemandAbsenceEndDay(var Item: Record Item; var WorkCenterNo: Code[20]; var ShipmentDate: Date; var PlanningFromDate: Date; var PlanningToDate: Date; RunTime: Integer; TimeShift: Boolean)
    var
        WorkCenter: Record "Work Center";
        AbsenceDate: Date;
    begin
        CreateAbscenceShipmentPlanningFromToDatesSetup(AbsenceDate, ShipmentDate, PlanningFromDate, PlanningToDate);
        CreateWorkCenterWithAbsenceInTheEndOfDay(WorkCenter, AbsenceDate, PlanningFromDate, PlanningToDate, TimeShift);
        CreateWorkCenterDemand(Item, WorkCenter."No.", RunTime, ShipmentDate);
        WorkCenterNo := WorkCenter."No.";
    end;

    local procedure WorkCenterAndDemandAbsenceWholeDay(var Item: Record Item; var WorkCenterNo: Code[20]; var ShipmentDate: Date; var PlanningFromDate: Date; var PlanningToDate: Date; RunTime: Integer; TimeShift: Boolean)
    var
        WorkCenter: Record "Work Center";
        AbsenceDate: Date;
    begin
        CreateAbscenceShipmentPlanningFromToDatesSetup(AbsenceDate, ShipmentDate, PlanningFromDate, PlanningToDate);
        CreateWorkCenterWithTheWholeDayAbsence(WorkCenter, AbsenceDate, PlanningFromDate, PlanningToDate, TimeShift);
        CreateWorkCenterDemand(Item, WorkCenter."No.", RunTime, ShipmentDate);
        WorkCenterNo := WorkCenter."No.";
    end;

    local procedure PlanBackwardReplanForwardCreateConstrainedResourcePlanBackwardReplanForwardVerifyZeroRunTime(var Item: Record Item; WorkCenterNo: Code[20]; ShipmentDate: Date; PlanningFromDate: Date; PlanningToDate: Date)
    var
        RequisitionLine: Record "Requisition Line";
        StartingEndingDateTime: DateTime;
    begin
        LibraryPlanning.CalcRegenPlanForPlanWkshPlanningParams(Item, PlanningFromDate, PlanningToDate, true);
        FindRequisitionLine(RequisitionLine, Item."No.");
        Assert.RecordCount(RequisitionLine, 1);
        RequisitionLine.TestField("Starting Date-Time", RequisitionLine."Ending Date-Time");
        StartingEndingDateTime := RequisitionLine."Starting Date-Time";

        ReplanForwardCreateConstrainedResourcePlanBackwardReplanForwardVerify(
          Item, RequisitionLine, WorkCenterNo, ShipmentDate, PlanningFromDate, PlanningToDate, StartingEndingDateTime, StartingEndingDateTime);
    end;

    local procedure PlanBackwardReplanForwardCreateConstrainedResourcePlanBackwardReplanForwardVerifyPositiveRunTime(var Item: Record Item; WorkCenterNo: Code[20]; ShipmentDate: Date; PlanningFromDate: Date; PlanningToDate: Date)
    var
        RequisitionLine: Record "Requisition Line";
        StartingDateTime: DateTime;
        EndingDateTime: DateTime;
    begin
        LibraryPlanning.CalcRegenPlanForPlanWkshPlanningParams(Item, PlanningFromDate, PlanningToDate, true);
        FindRequisitionLine(RequisitionLine, Item."No.");
        Assert.RecordCount(RequisitionLine, 1);
        StartingDateTime := RequisitionLine."Starting Date-Time";
        EndingDateTime := RequisitionLine."Ending Date-Time";

        ReplanForwardCreateConstrainedResourcePlanBackwardReplanForwardVerify(
          Item, RequisitionLine, WorkCenterNo, ShipmentDate, PlanningFromDate, PlanningToDate, StartingDateTime, EndingDateTime);
    end;

    local procedure ReplanForwardCreateConstrainedResourcePlanBackwardReplanForwardVerify(var Item: Record Item; var RequisitionLine: Record "Requisition Line"; WorkCenterNo: Code[20]; ShipmentDate: Date; PlanningFromDate: Date; PlanningToDate: Date; StartingDateTime: DateTime; EndingDateTime: DateTime)
    var
        CapacityConstrainedResource: Record "Capacity Constrained Resource";
        ScheduleDirection: Option Forward,Backward;
    begin
        LibraryPlanning.RefreshPlanningLine(RequisitionLine, ScheduleDirection::Forward, true, true);

        VerifyRequisitionLineStartingEndingDateTime(Item."No.", ShipmentDate, StartingDateTime, EndingDateTime);

        FindRequisitionLine(RequisitionLine, Item."No.");
        RequisitionLine.Delete(true);

        LibraryManufacturing.CreateCapacityConstrainedResource(
          CapacityConstrainedResource, CapacityConstrainedResource."Capacity Type"::"Work Center", WorkCenterNo);

        LibraryPlanning.CalcRegenPlanForPlanWkshPlanningParams(Item, PlanningFromDate, PlanningToDate, true);

        VerifyRequisitionLineStartingEndingDateTime(Item."No.", ShipmentDate, StartingDateTime, EndingDateTime);

        FindRequisitionLine(RequisitionLine, Item."No.");
        LibraryPlanning.RefreshPlanningLine(RequisitionLine, ScheduleDirection::Forward, true, true);

        VerifyRequisitionLineStartingEndingDateTime(Item."No.", ShipmentDate, StartingDateTime, EndingDateTime);
    end;

    local procedure CalculateDateWithNonWorkingDays(FromDate: Date; ToDate: Date; SignFactor: Integer) DateWithNonWorkingDays: Date
    var
        BaseCalendarChange: Record "Base Calendar Change";
        Date: Record Date;
    begin
        if SignFactor > 0 then
            DateWithNonWorkingDays := ToDate
        else
            DateWithNonWorkingDays := FromDate;
        Date.SetRange("Period Start", FromDate, ToDate);
        Date.SetRange("Period Name", Format(BaseCalendarChange.Day::Sunday));
        DateWithNonWorkingDays := CalcDate('<' + Format(SignFactor * Date.Count) + 'D>', DateWithNonWorkingDays);  // Add or Substract Non-working days to date.

        // Use 7 for Sunday required for test.
        if Date2DWY(DateWithNonWorkingDays, 1) = 7 then
            DateWithNonWorkingDays := CalcDate('<' + Format(SignFactor) + 'D>', DateWithNonWorkingDays);
    end;

    local procedure CarryOutActionMessageOnPlanningWorksheet(ItemNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        FindRequisitionLine(RequisitionLine, ItemNo);
        RequisitionLine.Validate("Accept Action Message", true);
        RequisitionLine.Modify(true);
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);
    end;

    local procedure CarryOutRequisitionLine(var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; LocationCode: Code[10]; ExpectedReceiptDate: Date)
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionWkshName.SetRange("Template Type", RequisitionWkshName."Template Type"::"Req.");
        RequisitionWkshName.FindFirst();
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
        RequisitionLine.Validate(Type, RequisitionLine.Type::Item);
        RequisitionLine.Validate("No.", ItemNo);
        RequisitionLine.Validate("Order Date", WorkDate());
        RequisitionLine.Validate("Action Message", RequisitionLine."Action Message"::New);
        RequisitionLine.Validate("Accept Action Message", true);
        RequisitionLine.Validate("Location Code", LocationCode);
        RequisitionLine.Validate(Quantity, LibraryRandom.RandDec(100, 2));
        RequisitionLine.Modify(true);
        LibraryPlanning.CarryOutReqWksh(RequisitionLine, WorkDate(), WorkDate(), WorkDate(), ExpectedReceiptDate, '');  // Use Blank for YourRef.
        FindPurchaseLine(PurchaseLine, ItemNo);
    end;

    local procedure CalculateProductionOrder(var TempProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary; Item: Record Item; Quantity: Decimal)
    var
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        CreateAndRefreshReleasedProductionOrderWithQty(ProductionOrder, Item."No.", Quantity);

        ProdOrderRoutingLine.SetRange("Routing No.", Item."Routing No.");
        ProdOrderRoutingLine.FindSet();
        repeat
            TempProdOrderRoutingLine := ProdOrderRoutingLine;
            TempProdOrderRoutingLine.Insert();
        until ProdOrderRoutingLine.Next() = 0;

        ProdOrderLine.SetRange("Item No.", Item."No.");
        ProdOrderLine.FindFirst();
        ProdOrderLine.Delete(true);
    end;

    local procedure CreateSalesOrderWithQuantity(ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
    end;

    local procedure CreateRoutingWithSendahead(var RoutingHeader: Record "Routing Header"; WorkCenterNo: Code[20]; RunTime: Integer; SendaheadQuantity: Decimal)
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        CreateRoutingLineWithSendahead(RoutingHeader, '10', WorkCenterNo, RunTime, 0);
        CreateRoutingLineWithSendahead(RoutingHeader, '20', WorkCenterNo, RunTime, SendaheadQuantity);
        CreateRoutingLineWithSendahead(RoutingHeader, '30', WorkCenterNo, RunTime, SendaheadQuantity);
        CreateRoutingLineWithSendahead(RoutingHeader, '40', WorkCenterNo, RunTime, 0);
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
    end;

    local procedure CreateRoutingLineWithSendahead(var RoutingHeader: Record "Routing Header"; OperationNo: Code[10]; WorkCenterNo: Code[20]; RunTime: Integer; SendaheadQuantity: Decimal)
    var
        RoutingLine: Record "Routing Line";
    begin
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', OperationNo, RoutingLine.Type::"Work Center", WorkCenterNo);
        RoutingLine.Validate("Run Time", RunTime);
        RoutingLine.Validate("Send-Ahead Quantity", SendaheadQuantity);
        RoutingLine.Modify(true);
    end;

    local procedure CreateRoutingWithSendahead(var RoutingHeader: Record "Routing Header"; WorkCenterNo: Code[20]; SetupTime: Decimal; RunTime: Decimal; WaitTime: Decimal; MoveTime: Decimal; SendaheadQuantity: Decimal)
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        CreateRoutingLineWithSendahead(RoutingHeader, '10', WorkCenterNo, SetupTime, RunTime, WaitTime, MoveTime, SendAheadQuantity);
        CreateRoutingLineWithSendahead(RoutingHeader, '20', WorkCenterNo, SetupTime, RunTime, WaitTime, MoveTime, SendAheadQuantity);
        CreateRoutingLineWithSendahead(RoutingHeader, '30', WorkCenterNo, SetupTime, RunTime, WaitTime, MoveTime, SendAheadQuantity);
        CreateRoutingLineWithSendahead(RoutingHeader, '40', WorkCenterNo, SetupTime, RunTime, WaitTime, MoveTime, SendAheadQuantity);
        CreateRoutingLineWithSendahead(RoutingHeader, '50', WorkCenterNo, SetupTime, RunTime, WaitTime, MoveTime, SendAheadQuantity);
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
    end;

    local procedure CreateRoutingLineWithSendahead(var RoutingHeader: Record "Routing Header"; OperationNo: Code[10]; WorkCenterNo: Code[20]; SetupTime: Decimal; RunTime: Decimal; WaitTime: Decimal; MoveTime: Decimal; SendaheadQuantity: Decimal)
    var
        RoutingLine: Record "Routing Line";
    begin
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', OperationNo, RoutingLine.Type::"Work Center", WorkCenterNo);
        RoutingLine.Validate("Setup Time", SetupTime);
        RoutingLine.Validate("Run Time", RunTime);
        RoutingLine.Validate("Wait Time", WaitTime);
        RoutingLine.Validate("Move Time", MoveTime);
        RoutingLine.Validate("Send-Ahead Quantity", SendaheadQuantity);
        RoutingLine.Modify(true);
    end;

    local procedure CreateAndRefreshReleasedProductionOrder(var ProductionOrder: Record "Production Order"; ItemNo: Code[20])
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo, LibraryRandom.RandInt(5));
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);  // Use True for Calculate Lines, Routing and Components.
    end;

    local procedure CreateAndRefreshReleasedProductionOrderWithQty(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo, Quantity);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);  // Use True for Calculate Lines, Routing and Components.
    end;

    local procedure CreateBaseCalendarWithBaseCalendarChange(var BaseCalendar: Record "Base Calendar")
    var
        BaseCalendarChange: Record "Base Calendar Change";
    begin
        LibraryService.CreateBaseCalendar(BaseCalendar);
        LibraryInventory.CreateBaseCalendarChange(
          BaseCalendarChange, BaseCalendar.Code, BaseCalendarChange."Recurring System"::"Weekly Recurring", 0D,
          BaseCalendarChange.Day::Sunday);  // Use 0D for Date.
    end;

    local procedure CreateCertifiedProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; ItemNo: Code[20]; UnitOfMeasureCode: Code[10]; QuantityPer: Decimal)
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, UnitOfMeasureCode);
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ItemNo, QuantityPer);
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure CreateProductionBOMWithProdBOMAsComponent(var ProductionBOMHeader: Record "Production BOM Header"; NestedProductionBOMNo: Code[20]; UnitOfMeasureCode: Code[10]; QuantityPer: Decimal)
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, UnitOfMeasureCode);
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::"Production BOM", NestedProductionBOMNo, QuantityPer);
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure CreateInitialSetupForPlanning(var Location: Record Location; var Vendor: Record Vendor; var Item: Record Item; BaseCalendarCode: Code[10])
    begin
        UpdateInboundWhseHandlingTimeOnLocation(Location, BaseCalendarCode);
        CreateVendorWithLeadTimeCalculation(Vendor, BaseCalendarCode);
        CreateItemWithVendorNo(Item, Vendor."No.");
    end;

    local procedure CreateInitialSetupForPlanningWithBaseCalendar(var Location: Record Location; var Vendor: Record Vendor; var Item: Record Item)
    var
        BaseCalendar: Record "Base Calendar";
    begin
        CreateBaseCalendarWithBaseCalendarChange(BaseCalendar);
        CreateInitialSetupForPlanning(Location, Vendor, Item, BaseCalendar.Code);
    end;

    local procedure CreateItem(var Item: Record Item; ReplenishmentSystem: Enum "Replenishment System"; ManufacturingPolicy: Enum "Manufacturing Policy")
    begin
        LibraryVariableStorage.Enqueue(ChangeWillNotAffectMsg);  // Enqueue for MessageHandler.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate("Manufacturing Policy", ManufacturingPolicy);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::Order);
        Item.Validate("Order Tracking Policy", Item."Order Tracking Policy"::"Tracking & Action Msg.");
        Item.Modify(true);
    end;

    local procedure CreateLotProdMakeToOrderItemWithRoutingNo(var Item: Record Item; RoutingNo: Code[20])
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Manufacturing Policy", Item."Manufacturing Policy"::"Make-to-Order");
        Item.Validate("Routing No.", RoutingNo);
        Item.Modify(true);
    end;

    local procedure CreateProdOrderItem(var Item: Record Item; ReorderingPolicy: Enum "Reordering Policy"; OrderMultipleQuantity: Decimal; RoutingNo: Code[20])
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Reordering Policy", ReorderingPolicy);
        Item.Validate("Order Multiple", OrderMultipleQuantity);
        Item.Validate("Routing No.", RoutingNo);
        Item.Modify(true);
    end;

    local procedure CreateFixedReorderQtyItemWithRoutingNo(var Item: Record Item; RoutingNo: Code[20])
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Routing No.", RoutingNo);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Fixed Reorder Qty.");
        Item.Validate("Reorder Point", LibraryRandom.RandIntInRange(200, 300));
        Item.Validate("Reorder Quantity", LibraryRandom.RandIntInRange(100, 200));
        Item.Modify(true);
    end;

    local procedure CreateItemWithRouting(var Item: Record Item; var RoutingLine: Record "Routing Line"; var RoutingLine2: Record "Routing Line"; ItemTrackingCode: Code[10]; WithMachineCenter: Boolean)
    var
        MachineCenter: Record "Machine Center";
        RoutingHeader: Record "Routing Header";
        WorkCenter: Record "Work Center";
    begin
        LibraryInventory.CreateItem(Item);
        WorkCenter.FindFirst();
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '',
          CopyStr(
            LibraryUtility.GenerateRandomCode(RoutingLine.FieldNo("Operation No."), DATABASE::"Routing Line"), 1,
            LibraryUtility.GetFieldLength(DATABASE::"Routing Line", RoutingLine.FieldNo("Operation No."))),
          RoutingLine.Type::"Work Center", WorkCenter."No.");  // Use Blank for Version Code.
        if WithMachineCenter then begin
            MachineCenter.SetRange("Work Center No.", WorkCenter."No.");
            MachineCenter.FindFirst();
            LibraryManufacturing.CreateRoutingLine(
              RoutingHeader, RoutingLine2, '',
              CopyStr(
                LibraryUtility.GenerateRandomCode(RoutingLine2.FieldNo("Operation No."), DATABASE::"Routing Line"), 1,
                LibraryUtility.GetFieldLength(DATABASE::"Routing Line", RoutingLine2.FieldNo("Operation No."))),
              RoutingLine2.Type::"Machine Center", MachineCenter."No.");  // Use Blank for Version Code.
            UpdateRoutingLine(RoutingLine2, RoutingLine."Operation No.", '', LibraryRandom.RandInt(5));  // Use Blank for Previous Operation No.
            UpdateRoutingLine(RoutingLine, '', RoutingLine2."Operation No.", LibraryRandom.RandInt(5));  // Use Blank for Next Operation No.
        end else begin
            LibraryManufacturing.CreateRoutingLine(
              RoutingHeader, RoutingLine2, '',
              CopyStr(
                LibraryUtility.GenerateRandomCode(RoutingLine2.FieldNo("Operation No."), DATABASE::"Routing Line"), 1,
                LibraryUtility.GetFieldLength(DATABASE::"Routing Line", RoutingLine2.FieldNo("Operation No."))),
              RoutingLine2.Type::"Work Center", WorkCenter."No.");  // Use Blank for Version Code.
            UpdateRoutingLine(RoutingLine2, '', '', 0);  // Use Blank for Previous and Next Operation. Use 0 for Setup Time required for test.
            UpdateRoutingLine(RoutingLine, '', '', 0);  // Use Blank for Previous and Next Operation. Use 0 for Setup Time required for test.
        end;
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
        UpdateRoutingNoAndItemTrackingCodeOnItem(Item, RoutingHeader."No.", ItemTrackingCode);
    end;

    local procedure CreateItemWithVendorNo(var Item: Record Item; VendorNo: Code[20])
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Vendor No.", VendorNo);
        Item.Modify(true);
    end;

    local procedure CreateLotItemTrackingCode(): Code[10]
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        exit(ItemTrackingCode.Code);
    end;

    local procedure CreateLotItemWithProductionBOM(var Item: Record Item)
    var
        ChildItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItem(ChildItem);
        CreateCertifiedProductionBOM(ProductionBOMHeader, ChildItem."No.", Item."Base Unit of Measure", LibraryRandom.RandInt(5));
        Item.Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item.Validate("Item Tracking Code", CreateLotItemTrackingCode());
        Item.Modify(true);
    end;

    local procedure CreateItemWithReplenishmentSystem(var Item: Record Item; ReplenishmentSystem: Enum "Replenishment System")
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Item.Modify(true);
    end;

    local procedure CreatePurchaseOrder(var PurchaseLine: Record "Purchase Line"; VendorNo: Code[20]; ItemNo: Code[20]; LocationCode: Code[10]; ExpectedReceiptDate: Date)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        PurchaseHeader.Validate("Location Code", LocationCode);
        PurchaseHeader.Validate("Expected Receipt Date", ExpectedReceiptDate);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandDec(100, 2));
    end;

    local procedure CreateSalesOrder(var SalesLine: Record "Sales Line"; ItemNo: Code[20]; LocationCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesOrderWithShipmentDate(ItemNo: Code[20]; ShipmentDate: Date)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLineWithShipmentDate(
          SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, ShipmentDate, LibraryRandom.RandIntInRange(20, 30));
    end;

    local procedure CreateWorkCenterWithShopCalendarWorkingDays(var WorkCenter: Record "Work Center"; var ShopCalendarWorkingDays: Record "Shop Calendar Working Days")
    begin
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);

        ShopCalendarWorkingDays.SetRange("Shop Calendar Code", WorkCenter."Shop Calendar Code");
        ShopCalendarWorkingDays.FindFirst();
    end;

    local procedure CreateWorkCenterAbsence(WorkCenter: Record "Work Center"; AbsenceDate: Date; AbsenceFromTime: Time; AbsenceToTime: Time; CalendarFromDate: Date; CalendarToDate: Date)
    var
        CalendarAbsenceEntry: Record "Calendar Absence Entry";
    begin
        LibraryManufacturing.CreateCalendarAbsenceEntry(
          CalendarAbsenceEntry, CalendarAbsenceEntry."Capacity Type"::"Work Center", WorkCenter."No.",
          AbsenceDate, AbsenceFromTime, AbsenceToTime, 1);
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, CalendarFromDate, CalendarToDate);
    end;

    local procedure CreateWorkCenterWithAbsenceInTheBeginningOfDay(var WorkCenter: Record "Work Center"; AbsenceDate: Date; CalendarFromDate: Date; CalendarToDate: Date; TimeShift: Boolean)
    var
        ShopCalendarWorkingDays: Record "Shop Calendar Working Days";
        AbsenceFromTime: Time;
        AbsenceToTime: Time;
        AbsenceDuration: Integer;
    begin
        CreateWorkCenterWithShopCalendarWorkingDays(WorkCenter, ShopCalendarWorkingDays);
        AbsenceDuration := HoursInMs(LibraryRandom.RandIntInRange(2, 4));
        AbsenceFromTime := ShopCalendarWorkingDays."Starting Time";
        AbsenceToTime := AbsenceFromTime + AbsenceDuration;
        if TimeShift then
            AbsenceFromTime -= HoursInMs(LibraryRandom.RandIntInRange(2, 4));
        CreateWorkCenterAbsence(WorkCenter, AbsenceDate, AbsenceFromTime, AbsenceToTime, CalendarFromDate, CalendarToDate);
    end;

    local procedure CreateWorkCenterWithAbsenceInTheMiddleOfDay(var WorkCenter: Record "Work Center"; AbsenceDate: Date; CalendarFromDate: Date; CalendarToDate: Date)
    var
        ShopCalendarWorkingDays: Record "Shop Calendar Working Days";
        AbsenceFromTime: Time;
        AbsenceToTime: Time;
        AbsenceDuration: Integer;
    begin
        CreateWorkCenterWithShopCalendarWorkingDays(WorkCenter, ShopCalendarWorkingDays);
        AbsenceDuration := HoursInMs(LibraryRandom.RandIntInRange(2, 4));
        AbsenceFromTime := ShopCalendarWorkingDays."Starting Time" + HoursInMs(LibraryRandom.RandIntInRange(1, 2));
        AbsenceToTime := AbsenceFromTime + AbsenceDuration;
        CreateWorkCenterAbsence(WorkCenter, AbsenceDate, AbsenceFromTime, AbsenceToTime, CalendarFromDate, CalendarToDate);
    end;

    local procedure CreateWorkCenterWithAbsenceInTheEndOfDay(var WorkCenter: Record "Work Center"; AbsenceDate: Date; CalendarFromDate: Date; CalendarToDate: Date; TimeShift: Boolean)
    var
        ShopCalendarWorkingDays: Record "Shop Calendar Working Days";
        AbsenceFromTime: Time;
        AbsenceToTime: Time;
        AbsenceDuration: Integer;
    begin
        CreateWorkCenterWithShopCalendarWorkingDays(WorkCenter, ShopCalendarWorkingDays);
        AbsenceDuration := HoursInMs(LibraryRandom.RandIntInRange(2, 4));
        AbsenceToTime := ShopCalendarWorkingDays."Ending Time";
        AbsenceFromTime := AbsenceToTime - AbsenceDuration;
        if TimeShift then
            AbsenceToTime += HoursInMs(LibraryRandom.RandIntInRange(2, 4));
        CreateWorkCenterAbsence(WorkCenter, AbsenceDate, AbsenceFromTime, AbsenceToTime, CalendarFromDate, CalendarToDate);
    end;

    local procedure CreateWorkCenterWithTheWholeDayAbsence(var WorkCenter: Record "Work Center"; AbsenceDate: Date; CalendarFromDate: Date; CalendarToDate: Date; TimeShift: Boolean)
    var
        ShopCalendarWorkingDays: Record "Shop Calendar Working Days";
        AbsenceFromTime: Time;
        AbsenceToTime: Time;
    begin
        CreateWorkCenterWithShopCalendarWorkingDays(WorkCenter, ShopCalendarWorkingDays);
        AbsenceFromTime := ShopCalendarWorkingDays."Starting Time";
        AbsenceToTime := ShopCalendarWorkingDays."Ending Time";
        if TimeShift then begin
            AbsenceFromTime -= HoursInMs(LibraryRandom.RandIntInRange(2, 4));
            AbsenceToTime += HoursInMs(LibraryRandom.RandIntInRange(2, 4));
        end;
        CreateWorkCenterAbsence(WorkCenter, AbsenceDate, AbsenceFromTime, AbsenceToTime, CalendarFromDate, CalendarToDate);
    end;

    local procedure CreateTwoWorkCentersWithProductionBins(var WorkCenter: array[2] of Record "Work Center")
    var
        Location: Record Location;
        Bin: Record Bin;
        i: Integer;
    begin
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);
        for i := 1 to 2 do begin
            LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter[i]);
            WorkCenter[i].Validate("Location Code", Location.Code);
            LibraryWarehouse.CreateBin(Bin, Location.Code, '', '', '');
            WorkCenter[i].Validate("To-Production Bin Code", Bin.Code);
            LibraryWarehouse.CreateBin(Bin, Location.Code, '', '', '');
            WorkCenter[i].Validate("From-Production Bin Code", Bin.Code);
            WorkCenter[i].Modify(true);
        end;
    end;

    local procedure CreateVersionRoutingLine(var RoutingLine: Record "Routing Line"; var WorkCenter: array[2] of Record "Work Center")
    var
        RoutingHeader: Record "Routing Header";
        RoutingVersion: Record "Routing Version";
    begin
        CreateTwoWorkCentersWithProductionBins(WorkCenter);

        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '', RoutingLine.Type::"Work Center", WorkCenter[1]."No.");
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);

        LibraryManufacturing.CreateRoutingVersion(RoutingVersion, RoutingHeader."No.",
          LibraryUtility.GenerateRandomCode(RoutingLine.FieldNo("Version Code"), DATABASE::"Routing Line"));
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, RoutingVersion."Version Code", RoutingLine."Operation No.",
          RoutingLine.Type::"Work Center", WorkCenter[2]."No.");
        RoutingVersion.Validate(Status, RoutingVersion.Status::Certified);
        RoutingVersion.Modify(true);
    end;

    local procedure HoursInMs(Hours: Integer) Ms: Integer
    begin
        Ms := 60 * 60 * 1000 * Hours;
    end;

    local procedure CreateRoutingWithRunTime(var RoutingHeader: Record "Routing Header"; WorkCenterNo: Code[20]; RunTime: Integer)
    var
        RoutingLine: Record "Routing Line";
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '', RoutingLine.Type::"Work Center", WorkCenterNo);
        RoutingLine.Validate("Run Time", RunTime);
        RoutingLine.Modify(true);
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
    end;

    local procedure CreateUncertifiedRouting(var RoutingHeader: Record "Routing Header")
    var
        RoutingLine: Record "Routing Line";
        WorkCenter: Record "Work Center";
    begin
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '',
          LibraryUtility.GenerateRandomCode(RoutingLine.FieldNo("Operation No."), DATABASE::"Routing Line"),
          RoutingLine.Type::"Work Center", WorkCenter."No.");
    end;

    local procedure CreateWorkCenterDemand(var Item: Record Item; WorkCenterNo: Code[20]; RunTime: Integer; DueDate: Date)
    var
        RoutingHeader: Record "Routing Header";
    begin
        CreateRoutingWithRunTime(RoutingHeader, WorkCenterNo, RunTime);
        CreateLotProdMakeToOrderItemWithRoutingNo(Item, RoutingHeader."No.");
        CreateSalesOrderWithShipmentDate(Item."No.", DueDate);
    end;

    local procedure CreateVendorWithLeadTimeCalculation(var Vendor: Record Vendor; BaseCalendarCode: Code[10])
    var
        LeadTimeCalculation: DateFormula;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Evaluate(LeadTimeCalculation, '<' + Format(LibraryRandom.RandInt(5)) + 'D>');
        Vendor.Validate("Lead Time Calculation", LeadTimeCalculation);
        Vendor.Validate("Base Calendar Code", BaseCalendarCode);
        Vendor.Modify(true);
    end;

    local procedure CreateProductionForecastEntryWithBlankLocation(var ProductionForecastEntry: Record "Production Forecast Entry"; Item: Record Item; ProductionForecastName: Code[10]; ComponentForecast: Boolean)
    begin
        LibraryManufacturing.CreateProductionForecastEntry(
          ProductionForecastEntry, ProductionForecastName, Item."No.", '',
          WorkDate() + LibraryRandom.RandIntInRange(30, 60), ComponentForecast);
        ProductionForecastEntry.Validate("Unit of Measure Code", Item."Base Unit of Measure");
        ProductionForecastEntry.Validate("Forecast Quantity", LibraryRandom.RandIntInRange(1000, 2000));
        ProductionForecastEntry.Modify(true);
    end;

    local procedure CreateProductionForecastEntry(ProductionForecastName: Code[10]; Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; ForecastDate: Date; Qty: Decimal)
    var
        ProductionForecastEntry: Record "Production Forecast Entry";
    begin
        LibraryManufacturing.CreateProductionForecastEntry(
          ProductionForecastEntry, ProductionForecastName, Item."No.", LocationCode, ForecastDate, false);
        ProductionForecastEntry.Validate("Unit of Measure Code", Item."Base Unit of Measure");
        ProductionForecastEntry.Validate("Variant Code", VariantCode);
        ProductionForecastEntry.Validate("Forecast Quantity", Qty);
        ProductionForecastEntry.Modify(true);
    end;

    local procedure DeleteRequisitionLine(ItemNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetRange("No.", ItemNo);
        RequisitionLine.DeleteAll(true);
    end;

    local procedure ExplodeRoutingOnOutputJournal(OrderNo: Code[20]; HasItemTracking: Boolean)
    var
        ItemJournalLine: Record "Item Journal Line";
        Variant: Variant;
    begin
        LibraryInventory.ClearItemJournal(OutputItemJournalTemplate, OutputItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::Output, '', 0);
        ItemJournalLine.Validate("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.Validate("Order No.", OrderNo);
        ItemJournalLine.Modify(true);

        if HasItemTracking then
            LibraryVariableStorage.Enqueue(ConfirmDeleteItemTrackingQst); // Explode BOM - confirm delete if Item Tracking
        LibraryManufacturing.OutputJnlExplodeRoute(ItemJournalLine);
        if HasItemTracking then
            LibraryVariableStorage.Dequeue(Variant);
    end;

    local procedure FilterReservationEntry(var ReservationEntry: Record "Reservation Entry"; ItemNo: Code[20]; LotNo: Code[50])
    begin
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Prospect);
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.SetRange("Lot No.", LotNo);
    end;

    local procedure FindOutputJournalLine(var ItemJournalLine: Record "Item Journal Line"; ProductionOrder: Record "Production Order"; OperationNo: Code[10]; Type: Enum "Capacity Type Routing"; No: Code[20])
    begin
        ItemJournalLine.SetRange("Entry Type", ItemJournalLine."Entry Type"::Output);
        ItemJournalLine.SetRange("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.SetRange("Order No.", ProductionOrder."No.");
        ItemJournalLine.SetRange("Item No.", ProductionOrder."Source No.");
        ItemJournalLine.SetRange("Operation No.", OperationNo);
        ItemJournalLine.SetRange(Type, Type);
        ItemJournalLine.SetRange("No.", No);
        ItemJournalLine.FindFirst();
    end;

    local procedure FindProdOrderCapacityNeed(var ProdOrderCapacityNeed: Record "Prod. Order Capacity Need"; RoutingLine: Record "Routing Line"; ProductionOrderNo: Code[20]; TimeType: Enum "Routing Time Type")
    begin
        ProdOrderCapacityNeed.SetRange("Prod. Order No.", ProductionOrderNo);
        ProdOrderCapacityNeed.SetRange("Operation No.", RoutingLine."Operation No.");
        ProdOrderCapacityNeed.SetRange(Type, RoutingLine.Type);
        ProdOrderCapacityNeed.SetRange("No.", RoutingLine."No.");
        ProdOrderCapacityNeed.SetRange("Time Type", TimeType);
        ProdOrderCapacityNeed.FindFirst();
    end;

    local procedure FindProdOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; ProdOrderNo: Code[20]; ItemNo: Code[20])
    begin
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderComponent.SetRange("Item No.", ItemNo);
        ProdOrderComponent.FindFirst();
    end;

    local procedure FindProdOrderRoutingLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ProductionOrderNo: Code[20]; OperationNo: Code[10])
    begin
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrderNo);
        ProdOrderRoutingLine.SetRange("Operation No.", OperationNo);
        ProdOrderRoutingLine.FindFirst();
    end;

    local procedure FindPurchaseLine(var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20])
    begin
        PurchaseLine.SetRange("No.", ItemNo);
        PurchaseLine.FindFirst();
    end;

    local procedure FindRequisitionLine(var RequisitionLine: Record "Requisition Line"; ItemNo: Code[20])
    begin
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", ItemNo);
        RequisitionLine.FindFirst();
    end;

    local procedure FindProductionOrder(var ProductionOrder: Record "Production Order"; Type: Enum "Production Order Status"; No: Code[20])
    begin
        ProductionOrder.SetRange("Source Type", Type);
        ProductionOrder.SetRange("Source No.", No);
        ProductionOrder.FindFirst();
    end;

    local procedure GetDefaultSafetyLeadTime(): Code[10]
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        exit(Format(InventorySetup."Default Safety Lead Time"));
    end;

    local procedure PostOutputJournalAfterDeleteOutputJournalLine(ProductionOrder: Record "Production Order"; RoutingLine: Record "Routing Line"; RoutingLine2: Record "Routing Line"; Finished: Boolean)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        FindOutputJournalLine(ItemJournalLine, ProductionOrder, RoutingLine2."Operation No.", RoutingLine2.Type, RoutingLine2."No.");
        ItemJournalLine.Delete(true);
        UpdateFinishedOnOutputJournalLine(ProductionOrder, RoutingLine, Finished);
        LibraryInventory.PostItemJournalLine(OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);
    end;

    local procedure PostProductionJournalFromRPOWithLot(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]) LotNo: Code[50]
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, ItemNo);
        LotNo := LibraryUtility.GenerateGUID();
        LibraryVariableStorage.Enqueue(LotNo);  // Enqueue for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(PostJournalLinesConfirmQst);  // Enqueue for ConfirmHandler.
        LibraryVariableStorage.Enqueue(JournalLinesSuccessfullyPostedMsg);  // Enqueue for MessageHandler.
        ProdOrderLine.SetRange(Status, ProdOrderLine.Status::Released);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        LibraryManufacturing.OpenProductionJournal(ProductionOrder, ProdOrderLine."Line No.");  // Posting is performing on ProductionJournalPageHandler with Lot Item Tracking.
    end;

    local procedure IncreaseItemInventoryAtLocation(LocationCode: Code[10]; ItemNo: Code[20]) Quantity: Decimal
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        Quantity := LibraryRandom.RandIntInRange(10, 100);
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, LocationCode, '', Quantity);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure UpdateFinishedOnOutputJournalLine(ProductionOrder: Record "Production Order"; RoutingLine: Record "Routing Line"; Finished: Boolean)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        FindOutputJournalLine(ItemJournalLine, ProductionOrder, RoutingLine."Operation No.", RoutingLine.Type, RoutingLine."No.");
        ItemJournalLine.Validate(Finished, Finished);
        ItemJournalLine.Modify(true);
    end;

    local procedure UpdateFinishedRoutingStatusOnProdOrderRoutingLine(ProductionOrderNo: Code[20]; OperationNo: Code[10])
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        LibraryVariableStorage.Enqueue(YouWantToContinueConfirmQst);  // Enqueue for ConfirmHandler.
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrderNo, OperationNo);
        ProdOrderRoutingLine.Validate("Routing Status", ProdOrderRoutingLine."Routing Status"::Finished);
        ProdOrderRoutingLine.Modify(true);
    end;

    local procedure UpdateInboundWhseHandlingTimeOnLocation(var Location: Record Location; BaseCalendarCode: Code[10])
    var
        InboundWhseHandlingTime: DateFormula;
    begin
        Evaluate(InboundWhseHandlingTime, '<' + Format(LibraryRandom.RandInt(5)) + 'D>');
        Location.Validate("Inbound Whse. Handling Time", InboundWhseHandlingTime);
        Location.Validate("Base Calendar Code", BaseCalendarCode);
        Location.Modify(true);
    end;

    local procedure UpdatePlanningWarningOnManufacturingSetup(var OldPlanningWarning: Boolean; NewPlanningWarning: Boolean)
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.Get();
        OldPlanningWarning := ManufacturingSetup."Planning Warning";
        ManufacturingSetup.Validate("Planning Warning", NewPlanningWarning);
        ManufacturingSetup.Modify(true);
    end;

    local procedure UpdateCurrentDemandForecastAndComponentsAtLocation(CurrentProductionForecast: Code[10]; ComponentsAtLocation: Code[10])
    begin
        LibraryPlanning.SetDemandForecast(CurrentProductionForecast);
        LibraryManufacturing.SetComponentsAtLocation(ComponentsAtLocation);
    end;

    local procedure UpdateUseForecastOnLocationsInManufacturingSetup(UseForecastOnLocations: Boolean)
    begin
        LibraryPlanning.SetUseForecastOnLocations(UseForecastOnLocations);
    end;

    local procedure UpdateUseForecastOnVariantsInManufacturingSetup(UseForecastOnVariants: Boolean)
    begin
        LibraryPlanning.SetUseForecastOnVariants(UseForecastOnVariants);
        
    end;

    local procedure UpdateQuantityOnSalesLine(var SalesLine: Record "Sales Line")
    begin
        SalesLine.Validate(Quantity, SalesLine.Quantity + LibraryRandom.RandDec(100, 2));  // Increase Quantity on Sales Line after calculate regenerative plan required for test.
        SalesLine.Modify(true);
    end;

    local procedure UpdateRoutingNoAndItemTrackingCodeOnItem(Item: Record Item; RoutingNo: Code[20]; ItemTrackingCode: Code[10])
    begin
        Item.Validate("Routing No.", RoutingNo);
        Item.Validate("Item Tracking Code", ItemTrackingCode);
        Item.Modify(true);
    end;

    local procedure UpdateRoutingLine(var RoutingLine: Record "Routing Line"; NextOperationNo: Code[30]; PreviousOperationNo: Code[30]; SetupTime: Decimal)
    begin
        RoutingLine.Validate("Previous Operation No.", PreviousOperationNo);
        RoutingLine.Validate("Next Operation No.", NextOperationNo);
        RoutingLine.Validate("Setup Time", SetupTime);
        RoutingLine.Validate("Run Time", LibraryRandom.RandInt(5));
        RoutingLine.Modify(true);
    end;

    local procedure UpdateWaitTimeOnProdOrderRoutingLine(ProductionOrderNo: Code[20]; OperationNo: Code[10])
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrderNo, OperationNo);
        ProdOrderRoutingLine.Validate("Wait Time", LibraryRandom.RandInt(5) + 50);  // Large value required for test.
        ProdOrderRoutingLine.Modify(true);
    end;

    local procedure VerifyEmptyReservationEntry(ItemNo: Code[20]; LotNo: Code[50])
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        FilterReservationEntry(ReservationEntry, ItemNo, LotNo);
        Assert.IsTrue(ReservationEntry.IsEmpty, ReservationEntryMustBeEmptyErr);
    end;

    local procedure VerifyItemLedgerEntry(ProductionOrder: Record "Production Order"; LotNo: Code[50])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        ItemLedgerEntry.SetRange("Item No.", ProductionOrder."Source No.");
        ItemLedgerEntry.SetRange("Lot No.", LotNo);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField(Quantity, ProductionOrder.Quantity);
    end;

    local procedure VerifyOutputJournalLine(ProductionOrder: Record "Production Order"; RoutingLine: Record "Routing Line")
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        FindOutputJournalLine(ItemJournalLine, ProductionOrder, RoutingLine."Operation No.", RoutingLine.Type, RoutingLine."No.");
        ItemJournalLine.TestField("Output Quantity", ProductionOrder.Quantity);
    end;

    local procedure VerifyPlanningDatesOnPurchaseLine(PurchaseLine: Record "Purchase Line"; OrderDate: Date; PlannedReceiptDate: Date; ExpectedReceiptDate: Date)
    begin
        PurchaseLine.TestField("Order Date", OrderDate);
        PurchaseLine.TestField("Planned Receipt Date", PlannedReceiptDate);
        PurchaseLine.TestField("Expected Receipt Date", ExpectedReceiptDate);
    end;

    local procedure VerifyProductionOrder(SalesLine: Record "Sales Line")
    var
        ProductionOrder: Record "Production Order";
    begin
        ProductionOrder.SetRange("Source No.", SalesLine."No.");
        ProductionOrder.FindFirst();
        ProductionOrder.TestField("Location Code", SalesLine."Location Code");
        ProductionOrder.TestField(Quantity, SalesLine.Quantity);
    end;

    local procedure VerifyProdOrderCapacityNeedWithStartingTime(RoutingLine: Record "Routing Line"; ProductionOrderNo: Code[20]; SendAheadType: Option; TimeType: Enum "Routing Time Type"; StartingTime: Time; AllocatedTime: Decimal)
    var
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
    begin
        ProdOrderCapacityNeed.SetRange("Send-Ahead Type", SendAheadType);
        FindProdOrderCapacityNeed(ProdOrderCapacityNeed, RoutingLine, ProductionOrderNo, TimeType);
        ProdOrderCapacityNeed.TestField("Starting Time", StartingTime);
        ProdOrderCapacityNeed.TestField("Allocated Time", AllocatedTime);
    end;

    local procedure VerifyProductionOrderCapacityNeed(RoutingLine: Record "Routing Line"; ProductionOrderNo: Code[20]; TimeType: Enum "Routing Time Type"; AllocatedTime: Decimal)
    var
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
    begin
        FindProdOrderCapacityNeed(ProdOrderCapacityNeed, RoutingLine, ProductionOrderNo, TimeType);
        ProdOrderCapacityNeed.TestField("Allocated Time", AllocatedTime);
    end;

    local procedure VerifyRequisitionLine(SalesLine: Record "Sales Line"; ActionMessage: Enum "Action Message Type"; AcceptActionMessage: Boolean; RefOrderType: Enum "Requisition Ref. Order Type")
    var
        RequisitionLine: Record "Requisition Line";
    begin
        FindRequisitionLine(RequisitionLine, SalesLine."No.");
        RequisitionLine.TestField("Action Message", ActionMessage);
        RequisitionLine.TestField("Accept Action Message", AcceptActionMessage);
        RequisitionLine.TestField(Quantity, SalesLine.Quantity);
        RequisitionLine.TestField("Ref. Order Type", RefOrderType);
        RequisitionLine.TestField("Location Code", SalesLine."Location Code");
    end;

    local procedure VerifyRequisitionLineStartingEndingDateTime(ItemNo: Code[20]; ShipmentDate: Date; StartingDateTime: DateTime; EndingDateTime: DateTime)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        FindRequisitionLine(RequisitionLine, ItemNo);
        Assert.RecordCount(RequisitionLine, 1);
        Assert.IsTrue(ShipmentDate >= RequisitionLine."Due Date", DueDateErr);
        RequisitionLine.TestField("Starting Date-Time", StartingDateTime);
        RequisitionLine.TestField("Ending Date-Time", EndingDateTime);
    end;

    local procedure VerifyRequisitionLineCountAndQty(ItemNo: Code[20]; VariantCode: Code[10]; RecCount: Integer; Qty: Decimal)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetRange("No.", ItemNo);
        RequisitionLine.SetRange("Variant Code", VariantCode);
        RequisitionLine.CalcSums(Quantity);
        RequisitionLine.TestField(Quantity, Qty);
        Assert.RecordCount(RequisitionLine, RecCount);
    end;

    local procedure VerifyReservationEntry(ProductionOrder: Record "Production Order"; LotNo: Code[50])
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        FilterReservationEntry(ReservationEntry, ProductionOrder."Source No.", LotNo);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField("Quantity (Base)", ProductionOrder.Quantity);
    end;

    local procedure VerifyProductionOrderWithRoutingLine(WorkCenter: Record "Work Center"; ItemNo: Code[20]; OperationNo: Code[10])
    var
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        FindProductionOrder(ProductionOrder, ProductionOrder."Source Type"::Item, ItemNo);
        ProductionOrder.TestField("Bin Code", WorkCenter."From-Production Bin Code");

        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder."No.", OperationNo);
        ProdOrderRoutingLine.TestField("To-Production Bin Code", WorkCenter."To-Production Bin Code");
        ProdOrderRoutingLine.TestField("From-Production Bin Code", WorkCenter."From-Production Bin Code");
    end;

    local procedure VerifyProductionOrderWithRoutingLineBlankLocationAndBins(ItemNo: Code[20]; OperationNo: Code[10])
    var
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        FindProductionOrder(ProductionOrder, ProductionOrder."Source Type"::Item, ItemNo);
        ProductionOrder.TestField("Location Code", '');
        ProductionOrder.TestField("Bin Code", '');

        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder."No.", OperationNo);
        ProdOrderRoutingLine.TestField("Location Code", '');
        ProdOrderRoutingLine.TestField("To-Production Bin Code", '');
        ProdOrderRoutingLine.TestField("From-Production Bin Code", '');
    end;

    local procedure VerifyBinCodeOnPlanningComponent(Item: Record Item; BinCode: Code[20])
    var
        PlanningComponent: Record "Planning Component";
    begin
        PlanningComponent.SetRange("Item No.", Item."No.");
        PlanningComponent.FindFirst();
        Assert.AreEqual(BinCode, PlanningComponent."Bin Code", BinCodesNotEqualErr);
    end;

    local procedure CreateAndReleaseSalesOrder(ItemNo: Code[20]; LocationCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', ItemNo, 1, LocationCode, 0D);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateAndPostPurchaseOrderWithBin(var Items: array[3] of Record Item; BinCode: Code[20]; LocationCode: Code[10])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        CreatePurchaseOrderLine(Purchaseheader, Items[1], BinCode, LocationCode);
        CreatePurchaseOrderLine(Purchaseheader, Items[2], BinCode, LocationCode);
        CreatePurchaseOrderLine(Purchaseheader, Items[3], BinCode, LocationCode);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreatePurchaseOrderLine(var PurchaseHeader: Record "Purchase Header"; Item: Record Item; BinCode: Code[20]; LocationCode: Code[10])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 100);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Validate("Bin Code", BinCode);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateRoutingLinks(var RoutingLinks: array[2] of Record "Routing Link")
    begin
        LibraryManufacturing.CreateRoutingLink(RoutingLinks[1]);
        LibraryManufacturing.CreateRoutingLink(RoutingLinks[2]);
    end;

    local procedure CreateRouting(var Item: Record Item; var WorkCenter: Record "Work Center"; var MachineCenters: array[2] of Record "Machine Center"; var RoutingLinks: array[2] of Record "Routing Link")
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        RoutingLine.Type := RoutingLine.Type::"Machine Center";
        CreateRoutingLine(RoutingLine, RoutingHeader, MachineCenters[1]."No.", RoutingLinks[1].Code);
        RoutingLine.Type := RoutingLine.Type::"Machine Center";
        CreateRoutingLine(RoutingLine, RoutingHeader, MachineCenters[2]."No.", RoutingLinks[2].Code);
        RoutingLine.Type := RoutingLine.Type::"Work Center";
        CreateRoutingLine(RoutingLine, RoutingHeader, WorkCenter."No.", '');
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
        Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Modify(true);
    end;

    local procedure CreateRoutingLine(var RoutingLine: Record "Routing Line"; RoutingHeader: Record "Routing Header"; CenterNo: Code[20]; RoutingLinkCode: Code[10])
    var
        OperationNo: Code[10];
    begin
        // Random used such that the Next Operation No is greater than the Previous Operation No.
        OperationNo := FindLastOperationNo(RoutingHeader."No.") + Format(LibraryRandom.RandInt(5));

        LibraryManufacturing.CreateRoutingLineSetup(RoutingLine, RoutingHeader, CenterNo, OperationNo, 0, 0);
        RoutingLine.Validate("Routing Link Code", RoutingLinkCode);
        RoutingLine.Modify(true);
    end;

    local procedure FindLastOperationNo(RoutingNo: Code[20]): Code[10]
    var
        RoutingLine: Record "Routing Line";
    begin
        RoutingLine.SetRange("Routing No.", RoutingNo);
        if RoutingLine.FindLast() then
            exit(RoutingLine."Operation No.");
    end;

    local procedure CreateMachineCentersWithBins(var MachineCenters: array[2] of Record "Machine Center"; var WorkCenter: Record "Work Center"; var Bins: array[7] of Record Bin)
    begin
        LibraryManufacturing.CreateMachineCenter(MachineCenters[1], WorkCenter."No.", 1);
        MachineCenters[1].Validate("Open Shop Floor Bin Code", Bins[1].Code);
        MachineCenters[1].Validate("To-Production Bin Code", Bins[2].Code);
        MachineCenters[1].Modify(true);
        LibraryManufacturing.CreateMachineCenter(MachineCenters[2], WorkCenter."No.", 1);
        MachineCenters[2].Validate("Open Shop Floor Bin Code", Bins[3].Code);
        MachineCenters[2].Validate("To-Production Bin Code", Bins[4].Code);
        MachineCenters[2].Modify(true);
    end;

    local procedure CreateWorkCenterWithLocation(var WorkCenter: Record "Work Center"; LocationCode: Code[10])
    begin
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        WorkCenter.Validate("Location Code", LocationCode);
        WorkCenter.Modify(true);
    end;

    local procedure CreateBinsOnLocation(var Bins: array[5] of Record Bin; var Location: Record Location)
    begin
        LibraryWarehouse.CreateBin(Bins[1], Location.Code, '', '', '');
        LibraryWarehouse.CreateBin(Bins[2], Location.Code, '', '', '');
        LibraryWarehouse.CreateBin(Bins[3], Location.Code, '', '', '');
        LibraryWarehouse.CreateBin(Bins[4], Location.Code, '', '', '');
        LibraryWarehouse.CreateBin(Bins[5], Location.Code, '', '', '');
    end;

    local procedure CreateComponentItems(var Items: array[3] of Record Item)
    begin
        // Create Component Items
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(Items[1], LibraryRandom.RandDec(1000, 2), LibraryRandom.RandDec(1000, 2));
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(Items[2], LibraryRandom.RandDec(1000, 2), LibraryRandom.RandDec(1000, 2));
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(Items[3], LibraryRandom.RandDec(1000, 2), LibraryRandom.RandDec(1000, 2));
    end;

    local procedure CreateAndCertifyProdBOMWithMultipleComponents(var Item: Record Item; var Items: array[3] of Record Item; var RoutingLinks: array[2] of Record "Routing Link")
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");
        CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, Items[1], RoutingLinks[1].Code);
        CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, Items[2], RoutingLinks[1].Code);
        CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, Items[3], RoutingLinks[2].Code);
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);
        Item.Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item.Modify(true);
    end;

    local procedure CreateProductionBOMLine(var ProductionBOMHeader: Record "Production BOM Header"; var ProductionBOMLine: Record "Production BOM Line"; Item: Record Item; RoutingLinkCode: Code[10])
    begin
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item."No.", 1);
        ProductionBOMLine.Validate("Routing Link Code", RoutingLinkCode);
        ProductionBOMLine.Modify(true);
    end;

    local procedure CreateAndUpdateLocation(var Location: Record Location; RequirePutAway: Boolean; RequirePick: Boolean; RequireReceive: Boolean; RequireShipment: Boolean; BinMandatory: Boolean)
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateLocationWMS(Location, BinMandatory, RequirePutAway, RequirePick, RequireReceive, RequireShipment);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
    end;

    local procedure VefiryTimeBetweenOperations(ProdOrderNo: Code[20])
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        StartingTime: Time;
        Difference: Integer;
    begin
        StartingTime := 0T;
        Difference := 300000;
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderRoutingLine.FindSet();
        repeat
            if StartingTime = 0T then
                StartingTime := ProdOrderRoutingLine."Starting Time"
            else begin
                Assert.AreEqual(Difference, ProdOrderRoutingLine."Starting Time" - StartingTime, '');
                StartingTime := ProdOrderRoutingLine."Starting Time";
            end;
        until ProdOrderRoutingLine.Next() = 0;
    end;

    local procedure CreateItemWithOrderTrackingPolicy(var Item: Record Item; OrderTrackingPolicy: Enum "Order Tracking Policy")
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Order Tracking Policy", OrderTrackingPolicy);
        Item.Modify(true);
    end;

    local procedure RunRequisitionCarryOutReportAssemblyOrder(RequisitionLine: Record "Requisition Line")
    var
        CarryOutActionMsgPlan: Report "Carry Out Action Msg. - Plan.";
        NewAsmOrderChoice: Enum "Planning Create Assembly Order";
    begin
        CarryOutActionMsgPlan.SetReqWkshLine(RequisitionLine);
        CarryOutActionMsgPlan.InitializeRequest(0, 0, 0, NewAsmOrderChoice::"Make Assembly Orders".Asinteger());
        CarryOutActionMsgPlan.UseRequestPage(false);
        CarryOutActionMsgPlan.RunModal();
    end;

    local procedure CreateProductionForecastEntryWithComponent(ProductionForecastName: Code[10]; Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; ForecastDate: Date; Qty: Decimal)
    var
        ProductionForecastEntry: Record "Production Forecast Entry";
    begin
        LibraryManufacturing.CreateProductionForecastEntry(
          ProductionForecastEntry, ProductionForecastName, Item."No.", LocationCode, ForecastDate, true);
        ProductionForecastEntry.Validate("Unit of Measure Code", Item."Base Unit of Measure");
        ProductionForecastEntry.Validate("Variant Code", VariantCode);
        ProductionForecastEntry.Validate("Forecast Quantity", Qty);
        ProductionForecastEntry.Modify(true);
    end;

    local procedure CalcRequisitionPlanForReqWkshWithMfg(var Item: Record Item; StartDate: Date; EndDate: Date)
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        LibraryPlanning.SelectRequisitionWkshName(RequisitionWkshName, RequisitionWkshName."Template Type"::"Req.");
        CalculatePlanForReqWkshWithMfg(Item, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name, StartDate, EndDate);
    end;

    local procedure CalculatePlanForReqWkshWithMfg(var Item: Record Item; TemplateName: Code[10]; WorksheetName: Code[10]; StartDate: Date; EndDate: Date)
    var
        TmpItem: Record Item;
        CalculatePlanReqWksh: Report "Calculate Plan - Req. Wksh.";
    begin
        CalculatePlanReqWksh.SetTemplAndWorksheet(TemplateName, WorksheetName);
        CalculatePlanReqWksh.InitializeRequest(StartDate, EndDate);
        CalculatePlanReqWksh.InitializeFromSetup();
        if Item.HasFilter then
            TmpItem.CopyFilters(Item)
        else begin
            Item.Get(Item."No.");
            TmpItem.SetRange("No.", Item."No.");
        end;
        CalculatePlanReqWksh.SetTableView(TmpItem);
        CalculatePlanReqWksh.UseRequestPage(false);
        CalculatePlanReqWksh.RunModal();
    end;

    local procedure CreateSalesOrderWithQuantityAndLocation(
        var SalesLine: Record "Sales Line"; ItemNo: Code[20];
        LocationCode: Code[10]; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
    end;

    local procedure VerifyOrderTracking(
        PurchaseLine: Record "Purchase Line"; TotalQuantity: Decimal;
        Quantity: array[2] of Decimal; ItemNo: Code[20])
    var
        OrderTracking2: Page "Order Tracking";
        OrderTracking: TestPage "Order Tracking";
    begin
        OrderTracking.Trap();
        OrderTracking2.SetVariantRec(PurchaseLine, PurchaseLine."No.", PurchaseLine."Outstanding Qty. (Base)", PurchaseLine."Expected Receipt Date", PurchaseLine."Expected Receipt Date");
        OrderTracking2.Run();
        OrderTracking.CurrItemNo.AssertEquals(ItemNo);
        OrderTracking."Total Quantity".AssertEquals(TotalQuantity);
        OrderTracking."Item No.".AssertEquals(ItemNo);
        OrderTracking.Quantity.AssertEquals(Quantity[1]);
        OrderTracking.Next();
        OrderTracking.Quantity.AssertEquals(Quantity[2]);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);
        Assert.IsTrue(StrPos(ConfirmMessage, ExpectedMessage) > 0, ConfirmMessage);
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        DequeueVariable: Variant;
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        ItemTrackingLines."Lot No.".SetValue(DequeueVariable);
        ItemTrackingLines."Quantity (Base)".SetValue(ItemTrackingLines.Quantity3.AsDecimal());
        ItemTrackingLines.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    var
        DequeueVariable: Variant;
        LocalMessage: Text[1024];
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        LocalMessage := DequeueVariable;
        Assert.IsTrue(StrPos(Message, LocalMessage) > 0, Message);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure SimpleMessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProductionJournalPageHandler(var ProductionJournal: TestPage "Production Journal")
    begin
        ProductionJournal.Last();
        ProductionJournal.ItemTrackingLines.Invoke();
        ProductionJournal.Post.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PlanningErrorLogModalPageHandler(var PlanningErrorLog: TestPage "Planning Error Log")
    var
        ExpectedError: Text;
    begin
        PlanningErrorLog.First();
        PlanningErrorLog."Item No.".AssertEquals(LibraryVariableStorage.DequeueText());
        ExpectedError := LibraryVariableStorage.DequeueText();
        Assert.ExpectedMessage(
          StrSubstNo(ExpectedError, LibraryVariableStorage.DequeueText()), PlanningErrorLog."Error Description".Value);
        Assert.IsFalse(PlanningErrorLog.Next(), OnlyOneRecordErr);
        PlanningErrorLog.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CreateOrderFromSalesModalPageHandler(var CreateOrderFromSales: TestPage "Create Order From Sales")
    begin
        CreateOrderFromSales.Yes().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CheckProdOrderStatusModalPageHandler(var CheckProdOrderStatus: TestPage "Check Prod. Order Status")
    begin
        CheckProdOrderStatus.Yes().Invoke();
    end;
}

