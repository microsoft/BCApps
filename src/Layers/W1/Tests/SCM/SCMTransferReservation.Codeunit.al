codeunit 137269 "SCM Transfer Reservation"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Transfer Order] [Reservation] [SCM]
    end;

    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryJob: Codeunit "Library - Job";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        ReservationEntryShipmentDateIncorrectErr: Label 'Reservation Entry Shipment Date is incorrect.';
        Direction: Option Outbound,Inbound;
        ItemTrackingOption: Option AssignLotNo,SelectEntries,ChangeLotQty,AssignSerialNos;
        CounterOfConfirms: Integer;
        DummyQst: Label 'Dummy Dialog Question?';
        ConfirmDialogOccursErr: Label 'Confirm Dialog occurs.';
        ExpectedDateConfclictErr: Label 'The change leads to a date conflict with existing reservations';
        UnexpectedErr: Label 'Unexpected Error occured.';
        ReservEntryQtyIncorrectErr: Label 'Reservation Entry Quantity is different than expected.';
        ReservationFromStockErr: Label 'Reservation from Stock must be %1 in %2.', Comment = '%1= Field Value, %2 =Table Caption.';

    [Test]
    [Scope('OnPrem')]
    procedure SalesLineReservationShipmentDate()
    var
        TransferLine: Record "Transfer Line";
        SalesLine: Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
        DemandDate: Date;
    begin
        // [FEATURE] [Shipment Date] [Transfer Receipt]
        // [SCENARIO 380276] Transfer Line Autoreserve Inbound to Sales Line: "Reservation Entry"."Shipment Date" must be equal to "Sales Line"."Shipment Date"
        Initialize();

        // [GIVEN] Supply from Transfer Line Reserved Outbound
        CreateSupplyFromTransferLineQtyOneReservedOutbound(TransferLine);

        // [GIVEN] Demand from Sales Line with Demand Date corresponding to Supply Date
        DemandDate := TransferLine."Receipt Date" + LibraryRandom.RandInt(30);
        CreateDemandFromSalesOrderLineQtyOne(SalesLine, TransferLine."Item No.", TransferLine."Transfer-to Code", DemandDate);

        // [WHEN] Autoreserve Transfer Line Inbound
        AutoReserveTransferLineInbound(TransferLine, DemandDate);

        FindTransferInboundReservationEntry(ReservationEntry, TransferLine."Item No.", TransferLine."Document No.");

        // [THEN] "Reservation Entry"."Shipment Date" must be equal to Demand Date
        Assert.AreEqual(DemandDate, ReservationEntry."Shipment Date", ReservationEntryShipmentDateIncorrectErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferLineReservationShipmentDate()
    var
        SupplyTransferLine: Record "Transfer Line";
        DemandTransferLine: Record "Transfer Line";
        ReservationEntry: Record "Reservation Entry";
        DemandDate: Date;
    begin
        // [FEATURE] [Shipment Date] [Transfer Receipt]
        // [SCENARIO 380276] Transfer Line Autoreserve Inbound to Transfer Line: "Reservation Entry"."Shipment Date" must be equal to Demand from Date "Transfer Line"."Shipment Date"
        Initialize();

        // [GIVEN] Supply from Transfer Line Reserved Outbound
        CreateSupplyFromTransferLineQtyOneReservedOutbound(SupplyTransferLine);

        // [GIVEN] Demand from Sales Line with Demand Date corresponding to Supply Date
        DemandDate := SupplyTransferLine."Receipt Date" + LibraryRandom.RandInt(30);
        CreateDemandFromTransferLineQtyOne(
          DemandTransferLine, SupplyTransferLine."Item No.", SupplyTransferLine."Transfer-to Code", DemandDate);

        // [WHEN] Autoreserve Transfer Line Inbound
        AutoReserveTransferLineInbound(SupplyTransferLine, DemandDate);

        FindTransferInboundReservationEntry(ReservationEntry, SupplyTransferLine."Item No.", SupplyTransferLine."Document No.");

        // [THEN] "Reservation Entry"."Shipment Date" must be equal to Demand Date
        Assert.AreEqual(DemandDate, ReservationEntry."Shipment Date", ReservationEntryShipmentDateIncorrectErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceLineReservationShipmentDate()
    var
        TransferLine: Record "Transfer Line";
        ServiceLine: Record "Service Line";
        ReservationEntry: Record "Reservation Entry";
        DemandDate: Date;
    begin
        // [FEATURE] [Shipment Date] [Transfer Receipt]
        // [SCENARIO 380276] Transfer Line Autoreserve Inbound to Service Line: "Reservation Entry"."Shipment Date" must be equal to "Service Line"."Needed by Date"
        Initialize();

        // [GIVEN] Supply from Transfer Line Reserved Outbound
        CreateSupplyFromTransferLineQtyOneReservedOutbound(TransferLine);

        // [GIVEN] Demand from Service Line with Demand Date corresponding to Supply Date
        DemandDate := TransferLine."Receipt Date" + LibraryRandom.RandInt(30);
        CreateDemandFromServiceLineQtyOne(ServiceLine, TransferLine."Item No.", TransferLine."Transfer-to Code", DemandDate);

        // [WHEN] Autoreserve Transfer Line Inbound
        AutoReserveTransferLineInbound(TransferLine, DemandDate);

        FindTransferInboundReservationEntry(ReservationEntry, TransferLine."Item No.", TransferLine."Document No.");

        // [THEN] "Reservation Entry"."Shipment Date" must be equal to Demand Date
        Assert.AreEqual(DemandDate, ReservationEntry."Shipment Date", ReservationEntryShipmentDateIncorrectErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobPlanningLineReservationShipmentDate()
    var
        TransferLine: Record "Transfer Line";
        JobPlanningLine: Record "Job Planning Line";
        ReservationEntry: Record "Reservation Entry";
        DemandDate: Date;
    begin
        // [FEATURE] [Shipment Date] [Transfer Receipt] [Job]
        // [SCENARIO 380276] Transfer Line Autoreserve Inbound to Job Planning Line: "Reservation Entry"."Shipment Date" must be equal to "Job Planning Line"."Planning Date"
        Initialize();

        // [GIVEN] Supply from Transfer Line Reserved Outbound
        CreateSupplyFromTransferLineQtyOneReservedOutbound(TransferLine);

        // [GIVEN] Demand from Sales Line with Demand Date corresponding to Supply
        DemandDate := TransferLine."Receipt Date" + LibraryRandom.RandInt(30);
        CreateDemandFromJobPlanningLineQtyOne(JobPlanningLine, TransferLine."Item No.", TransferLine."Transfer-to Code", DemandDate);

        // [WHEN] Autoreserve Transfer Line Inbound
        AutoReserveTransferLineInbound(TransferLine, DemandDate);

        FindTransferInboundReservationEntry(ReservationEntry, TransferLine."Item No.", TransferLine."Document No.");

        // [THEN] "Reservation Entry"."Shipment Date" must be equal to Demand Date
        Assert.AreEqual(DemandDate, ReservationEntry."Shipment Date", ReservationEntryShipmentDateIncorrectErr);
    end;

    [Test]
    [HandlerFunctions('CounterOfConfirmsHandler')]
    [Scope('OnPrem')]
    procedure TransferHeaderNoConfirmOnUpdateLines()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        NewReceiptDate: Date;
        DemandDate: Date;
    begin
        // [FEATURE] [Transfer Order Header]
        // [SCENARIO 380276] No Confirm Dialog occurs when VALIDATE "Transfer Header"."Receipt Date".
        Initialize();

        // Stub for test handler if no error occurs
        RunDummyConfirm();

        // [GIVEN] New "Transfer Header"."Receipt Date" and Demand Date are corresponding for Inbound Autoreserve
        NewReceiptDate := WorkDate() + LibraryRandom.RandInt(30);
        DemandDate := NewReceiptDate + LibraryRandom.RandInt(30);

        // [GIVEN] Reserved Transfer Order and Demand
        CreateTransferOrderQtyOneReservedOutbound(TransferHeader, TransferLine);
        CreateReservedDemandQtyOne(TransferLine."Item No.", TransferLine."Transfer-to Code", DemandDate);

        // [WHEN] VALIDATE "Transfer Header"."Receipt Date"
        TransferHeader.Validate("Receipt Date", NewReceiptDate);

        // [THEN] No Confirm Dialog occurs
        Assert.AreEqual(1, CounterOfConfirms, ConfirmDialogOccursErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferLineErrorOnValidateReceiptDateCheckInbound()
    var
        TransferLine: Record "Transfer Line";
        NewReceiptDate: Date;
        DemandDate: Date;
    begin
        // [FEATURE] [Shipment Date] [Transfer Receipt]
        // [SCENARIO 380276] ERROR occurs when VALIDATE "Transfer Line"."Receipt Date" with bad for Inbound Autoreserve date
        Initialize();

        // [GIVEN] New "Transfer Line"."Receipt Date" and Demand Date are not corresponding for Inbound Autoreserve
        DemandDate := WorkDate() + LibraryRandom.RandInt(30);
        NewReceiptDate := DemandDate + LibraryRandom.RandInt(30);

        // [GIVEN] Outbound Reserved Transfer Line
        CreateTransferLineQtyOneReservedOutbound(TransferLine);

        // [GIVEN] Demand Line
        CreateUnreservedDemandQtyOne(TransferLine."Item No.", TransferLine."Transfer-to Code", DemandDate);

        // [WHEN] Transfer Line Inbound Autoreserve to Demand and VALIDATE "Transfer Line"."Receipt Date" with new Date that is not corresponding to Inbound Autoreserve
        AutoReserveTransferLineInbound(TransferLine, DemandDate);
        asserterror TransferLine.Validate("Receipt Date", NewReceiptDate);

        // [THEN] Error of Date Conflict occurs
        Assert.ExpectedError(ExpectedDateConfclictErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferLineErrorOnValidateShipmentDateCheckInbound()
    var
        TransferLine: Record "Transfer Line";
        NewShipmentDate: Date;
        DemandDate: Date;
    begin
        // [FEATURE] [Shipment Date] [Transfer Receipt]
        // [SCENARIO 380276] ERROR occurs when VALIDATE "Transfer Line"."Shipment Date" with bad for Inbound Autoreserve date
        Initialize();

        // [GIVEN] New "Transfer Line"."Shipment Date" and Demand Date are not corresponding for Inbound Autoreserve
        DemandDate := WorkDate() + LibraryRandom.RandInt(30);
        NewShipmentDate := DemandDate + LibraryRandom.RandInt(30);

        // [GIVEN] Outbound Reserved Transfer Line
        CreateTransferLineQtyOneReservedOutbound(TransferLine);

        // [GIVEN] Demand Line
        CreateUnreservedDemandQtyOne(TransferLine."Item No.", TransferLine."Transfer-to Code", DemandDate);

        // [WHEN] Transfer Line Inbound Autoreserved to Demand and VALIDATE "Transfer Line"."Shipment Date" with new Date that is not corresponding to Inbound Autoreserve
        AutoReserveTransferLineInbound(TransferLine, DemandDate);
        asserterror TransferLine.Validate("Shipment Date", NewShipmentDate);

        // [THEN] Error of Date Conflict occurs
        Assert.ExpectedError(ExpectedDateConfclictErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferLineErrorOnValidateShippingTimeCheckInbound()
    var
        TransferLine: Record "Transfer Line";
        DemandDate: Date;
        NewShippingTime: DateFormula;
    begin
        // [FEATURE] [Shipment Date] [Transfer Receipt]
        // [SCENARIO 380276] ERROR occurs when VALIDATE "Transfer Line"."Shipping Time" and bad date for Inbound Autoreserve date occurs
        Initialize();

        // [GIVEN] New "Transfer Line"."Shipping Time" leads to "Transfer Line"."Receipt Date" and Demand Date are not corresponding for Inbound Autoreserve
        DemandDate := WorkDate() + LibraryRandom.RandInt(30);
        Evaluate(NewShippingTime, '<+1Y>');

        // [GIVEN] Outbound Reserved Transfer Line
        CreateTransferLineQtyOneReservedOutbound(TransferLine);

        // [GIVEN] Demand Line
        CreateUnreservedDemandQtyOne(TransferLine."Item No.", TransferLine."Transfer-to Code", DemandDate);

        // [WHEN] Transfer Line Inbound Autoreserved to Demand and VALIDATE "Transfer Line"."Shipping Time" with new Date Formula that leads to uncorresponding dates for Inbound Autoreserve
        AutoReserveTransferLineInbound(TransferLine, DemandDate);
        asserterror TransferLine.Validate("Shipping Time", NewShippingTime);

        // [THEN] Error of Date Conflict occurs
        Assert.ExpectedError(ExpectedDateConfclictErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferLineErrorOnValidateOutboundWhseHandlingTimeCheckInbound()
    var
        TransferLine: Record "Transfer Line";
        DemandDate: Date;
        OutboundWhseHandlingTime: DateFormula;
    begin
        // [FEATURE] [Shipment Date] [Transfer Receipt]
        // [SCENARIO 380276] ERROR occurs when VALIDATE "Transfer Line"."Outbound Whse. Handling Time" and bad date for Inbound Autoreserve date occurs
        Initialize();

        // [GIVEN] New "Transfer Line"."Outbound Whse. Handling Time" leads to "Transfer Line"."Receipt Date" and Demand Date are not corresponding for Inbound Autoreserve
        DemandDate := WorkDate() + LibraryRandom.RandInt(30);
        Evaluate(OutboundWhseHandlingTime, '<+1Y>');

        // [GIVEN] Outbound Reserved Transfer Line
        CreateTransferLineQtyOneReservedOutbound(TransferLine);

        // [GIVEN] Demand Line
        CreateUnreservedDemandQtyOne(TransferLine."Item No.", TransferLine."Transfer-to Code", DemandDate);

        // [WHEN] Transfer Line Inbound Autoreserved to Demand and VALIDATE "Transfer Line"."Outbound Whse. Handling Time" with new Date Formula that leads to uncorresponding dates for Inbound Autoreserve
        AutoReserveTransferLineInbound(TransferLine, DemandDate);
        asserterror TransferLine.Validate("Outbound Whse. Handling Time", OutboundWhseHandlingTime);

        // [THEN] Error of Date Conflict occurs
        Assert.ExpectedError(ExpectedDateConfclictErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferLineErrorOnValidateInboundWhseHandlingTimeCheckInbound()
    var
        TransferLine: Record "Transfer Line";
        DemandDate: Date;
        InboundWhseHandlingTime: DateFormula;
    begin
        // [FEATURE] [Shipment Date] [Transfer Receipt]
        // [SCENARIO 380276] ERROR occurs when VALIDATE "Transfer Line"."Inbound Whse. Handling Time" and bad date for Inbound Autoreserve date occurs
        Initialize();

        // [GIVEN] New "Transfer Line"."Inbound Whse. Handling Time" leads to "Transfer Line"."Receipt Date" and Demand Date are not corresponding for Inbound Autoreserve
        DemandDate := WorkDate() + LibraryRandom.RandInt(30);
        Evaluate(InboundWhseHandlingTime, '<+1Y>');

        // [GIVEN] Outbound Reserved Transfer Line
        CreateTransferLineQtyOneReservedOutbound(TransferLine);

        // [GIVEN] Demand Line
        CreateUnreservedDemandQtyOne(TransferLine."Item No.", TransferLine."Transfer-to Code", DemandDate);

        // [WHEN] Transfer Line Inbound Autoreserved to Demand and VALIDATE "Transfer Line"."Inbound Whse. Handling Time" with new Date Formula that leads to uncorresponding dates for Inbound Autoreserve
        AutoReserveTransferLineInbound(TransferLine, DemandDate);
        asserterror TransferLine.Validate("Inbound Whse. Handling Time", InboundWhseHandlingTime);

        // [THEN] Error of Date Conflict occurs
        Assert.ExpectedError(ExpectedDateConfclictErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferLineErrorOnValidateShippingAgentServiceCodeCheckInbound()
    var
        TransferLine: Record "Transfer Line";
        DemandDate: Date;
        ShippingAgentServiceCode: Code[10];
        ShippingAgentCode: Code[10];
    begin
        // [FEATURE] [Shipment Date] [Transfer Receipt]
        // [SCENARIO 380276] ERROR occurs when VALIDATE "Transfer Line"."Shipping Agent Service Code" and bad date for Inbound Autoreserve date occurs
        Initialize();

        // [GIVEN] New "Transfer Line"."Shipping Agent Service Code" leads to "Transfer Line"."Receipt Date" and Demand Date are not corresponding for Inbound Autoreserve
        DemandDate := WorkDate() + LibraryRandom.RandInt(30);
        CreateShippingAgentServiceCodeWith1YShippingTime(ShippingAgentCode, ShippingAgentServiceCode);

        // [GIVEN] Outbound Reserved Transfer Line
        CreateTransferLineQtyOneReservedOutbound(TransferLine);

        // [GIVEN] Demand Line
        CreateUnreservedDemandQtyOne(TransferLine."Item No.", TransferLine."Transfer-to Code", DemandDate);

        // [WHEN] Transfer Line Inbound Autoreserved to Demand and VALIDATE "Transfer Line"."Shipping Agent Service Code" with new value that leads to uncorresponding dates for Inbound Autoreserve
        AutoReserveTransferLineInbound(TransferLine, DemandDate);
        TransferLine.Validate("Shipping Agent Code", ShippingAgentCode);
        asserterror TransferLine.Validate("Shipping Agent Service Code", ShippingAgentServiceCode);

        // [THEN] Error of Date Conflict occurs
        Assert.ExpectedError(ExpectedDateConfclictErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferOrderErrorOnValidateReceiptDateCheckInbound()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        NewReceiptDate: Date;
        DemandDate: Date;
    begin
        // [FEATURE] [Shipment Date] [Transfer Receipt]
        // [SCENARIO 380276] ERROR occurs when VALIDATE "Transfer Header"."Receipt Date" with bad for Inbound Autoreserve date
        Initialize();

        // [GIVEN] New "Transfer Header"."Receipt Date" and Demand Date are not corresponding for Inbound Autoreserve
        DemandDate := WorkDate() + LibraryRandom.RandInt(30);
        NewReceiptDate := DemandDate + LibraryRandom.RandInt(30);

        // [GIVEN] Outbound Reserved Transfer Order
        CreateTransferOrderQtyOneReservedOutbound(TransferHeader, TransferLine);

        // [GIVEN] Demand Line
        CreateUnreservedDemandQtyOne(TransferLine."Item No.", TransferLine."Transfer-to Code", DemandDate);

        // [WHEN] Transfer Line Inbound Autoreserved to Demand and VALIDATE "Transfer Header"."Receipt Date" with new Date that is not corresponding to Inbound Autoreserve
        AutoReserveTransferLineInbound(TransferLine, DemandDate);
        asserterror TransferHeader.Validate("Receipt Date", NewReceiptDate);

        // [THEN] Error of Date Conflict occurs
        Assert.ExpectedError(ExpectedDateConfclictErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferOrderErrorOnValidateShipmentDateCheckInbound()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        NewShipmentDate: Date;
        DemandDate: Date;
    begin
        // [FEATURE] [Shipment Date] [Transfer Receipt]
        // [SCENARIO 380276] ERROR occurs when VALIDATE "Transfer Header"."Shipment Date" with bad for Inbound Autoreserve date
        Initialize();

        // [GIVEN] New "Transfer Header"."Shipment Date" and Demand Date are not corresponding for Inbound Autoreserve
        DemandDate := WorkDate() + LibraryRandom.RandInt(30);
        NewShipmentDate := DemandDate + LibraryRandom.RandInt(30);

        // [GIVEN] Outbound Reserved Transfer Order
        CreateTransferOrderQtyOneReservedOutbound(TransferHeader, TransferLine);

        // [GIVEN] Demand Line
        CreateUnreservedDemandQtyOne(TransferLine."Item No.", TransferLine."Transfer-to Code", DemandDate);

        // [WHEN] Transfer Line Inbound Autoreserved to Demand and VALIDATE "Transfer Header"."Shipment Date" with new Date that is not corresponding to Inbound Autoreserve
        AutoReserveTransferLineInbound(TransferLine, DemandDate);
        asserterror TransferHeader.Validate("Shipment Date", NewShipmentDate);

        // [THEN] Error of Date Conflict occurs
        Assert.ExpectedError(ExpectedDateConfclictErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferOrderErrorOnValidateShippingTimeCheckInbound()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        DemandDate: Date;
        NewShippingTime: DateFormula;
    begin
        // [FEATURE] [Shipment Date] [Transfer Receipt]
        // [SCENARIO 380276] ERROR occurs when VALIDATE "Transfer Header"."Shipping Time" and bad date for Inbound Autoreserve date occurs
        Initialize();

        // [GIVEN] New "Transfer Header"."Shipping Time" leads to "Transfer Header"."Receipt Date" and Demand Date are not corresponding for Inbound Autoreserve
        DemandDate := WorkDate() + LibraryRandom.RandInt(30);
        Evaluate(NewShippingTime, '<+1Y>');

        // [GIVEN] Outbound Reserved Transfer Order
        CreateTransferOrderQtyOneReservedOutbound(TransferHeader, TransferLine);

        // [GIVEN] Demand Line
        CreateUnreservedDemandQtyOne(TransferLine."Item No.", TransferLine."Transfer-to Code", DemandDate);

        // [WHEN] Transfer Line Inbound Autoreserved to Demand and VALIDATE "Transfer Header"."Shipping Time" with new Date Formula that leads to uncorresponding dates for Inbound Autoreserve
        AutoReserveTransferLineInbound(TransferLine, DemandDate);
        asserterror TransferHeader.Validate("Shipping Time", NewShippingTime);

        // [THEN] Error of Date Conflict occurs
        Assert.ExpectedError(ExpectedDateConfclictErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferOrderErrorOnValidateShippingAgentServiceCodeCheckInbound()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        DemandDate: Date;
        ShippingAgentServiceCode: Code[10];
        ShippingAgentCode: Code[10];
    begin
        // [FEATURE] [Shipment Date] [Transfer Receipt]
        // [SCENARIO 380276] ERROR occurs when VALIDATE "Transfer Header"."Shipping Agent Service Code" and bad date for Inbound Autoreserve date occurs
        Initialize();

        // [GIVEN] New "Transfer Header"."Shipping Agent Service Code" leads to "Transfer Header"."Receipt Date" and Demand Date are not corresponding for Inbound Autoreserve
        DemandDate := WorkDate() + LibraryRandom.RandInt(30);
        CreateShippingAgentServiceCodeWith1YShippingTime(ShippingAgentCode, ShippingAgentServiceCode);

        // [GIVEN] Outbound Reserved Transfer Order
        CreateTransferOrderQtyOneReservedOutbound(TransferHeader, TransferLine);

        // [GIVEN] Demand Line
        CreateUnreservedDemandQtyOne(TransferLine."Item No.", TransferLine."Transfer-to Code", DemandDate);

        // [WHEN] Transfer Line Inbound Autoreserved to Demand and VALIDATE "Transfer Line"."Inbound Whse. Handling Time" with new Date Formula that leads to uncorresponding dates for Inbound Autoreserve
        AutoReserveTransferLineInbound(TransferLine, DemandDate);
        TransferHeader.Validate("Shipping Agent Code", ShippingAgentCode);
        asserterror TransferHeader.Validate("Shipping Agent Service Code", ShippingAgentServiceCode);

        // [THEN] Error of Date Conflict occurs
        Assert.ExpectedError(ExpectedDateConfclictErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferLineErrorOnValidateReceiptDateCheckOutbound()
    var
        PurchaseLine: Record "Purchase Line";
        TransferLine: Record "Transfer Line";
        DemandDate: Date;
    begin
        // [FEATURE] [Shipment Date] [Transfer Shipment]
        // [SCENARIO 380276] Error occurs when trying to validate "Receipt Date" in "Transfer Line" table with a date leading to a reservation conflict
        Initialize();

        // [GIVEN] New "Transfer Line"."Receipt Date" and Demand Date are not corresponding for Outbound Autoreserve
        DemandDate := WorkDate() + LibraryRandom.RandInt(30);

        // [GIVEN] Supply from Purchase Line, Transfer Line as Demand
        CreateSupplyAndDemandFromTransferLine(PurchaseLine, TransferLine, DemandDate);
        // [GIVEN] Purchase Line autoreserved to outbound transfer
        AutoReservePurchaseLine(PurchaseLine, DemandDate);

        // [WHEN] Update "Receipt Date" on Transfer Line with an earlier date that will lead to a date conflict in reservation
        asserterror TransferLine.Validate("Receipt Date", WorkDate());

        // [THEN] Error of Date Conflict occurs
        Assert.ExpectedError(ExpectedDateConfclictErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferOrderErrorOnValidateReceiptDateCheckOutbound()
    var
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        DemandDate: Date;
    begin
        // [FEATURE] [Shipment Date] [Transfer Shipment]
        // [SCENARIO 380276] Error occurs when trying to validate "Receipt Date" in "Transfer Header" table with a date leading to a reservation conflict
        Initialize();

        // [GIVEN] New "Transfer Line"."Receipt Date" and Demand Date are not corresponding for Outbound Autoreserve
        DemandDate := WorkDate() + LibraryRandom.RandInt(30);

        // [GIVEN] Supply from Purchase Line, Transfer Order as Demand
        CreateSupplyAndDemandFromTransferOrder(PurchaseLine, TransferHeader, DemandDate);

        // [GIVEN] Purchase Line autoreserved to outbound transfer
        AutoReservePurchaseLine(PurchaseLine, DemandDate);

        // [WHEN] Update "Receipt Date" on Transfer Header with an earlier date that will lead to a date conflict in reservation
        asserterror TransferHeader.Validate("Receipt Date", WorkDate());

        // [THEN] Error of Date Conflict occurs
        Assert.ExpectedError(ExpectedDateConfclictErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SynchronizeTransferOutboundToInboundItemTrackingSNSpecific()
    var
        SalesLine: Record "Sales Line";
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        ProdOrderNo: Code[20];
    begin
        // [FEATURE] [Item Tracking]
        // [SCENARIO 381007] Synchronize Transfer Outbound To Inbound Item Tracking for SN Specific Tracking
        Initialize();

        // [GIVEN] Sales Order as Demand and released Production Order as Supply at different Locations reserved one to another via Transfer Order
        ProdOrderNo := CreateSOAsDemandAndPOAsSupplyAtDifferentLocations(SalesLine, TempTrackingSpecification, true, false);

        // [WHEN] post Output Journal for Item from Production Order with Tracking Specification with required tracking data
        CreateAndPostOutputJournalWithTrackingSpecification(TempTrackingSpecification, SalesLine."No.", ProdOrderNo);

        // [THEN] Provided by User Tracking Specification is transferred to Sales Order via Transfer Order
        VerifyTrackingSpecification(
          TempTrackingSpecification, DATABASE::"Sales Line", SalesLine."Document Type"::Order.AsInteger(),
          SalesLine."Document No.", '', 0, SalesLine."Line No.", -1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SynchronizeTransferOutboundToInboundItemTrackingLotSpecific()
    var
        SalesLine: Record "Sales Line";
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        ProdOrderNo: Code[20];
    begin
        // [FEATURE] [Item Tracking]
        // [SCENARIO 381007] Synchronize Transfer Outbound To Inbound Item Tracking for Lot Specific Tracking
        Initialize();

        // [GIVEN] Sales Order as Demand and released Production Order as Supply at different Locations reserved one to another via Transfer Order
        ProdOrderNo := CreateSOAsDemandAndPOAsSupplyAtDifferentLocations(SalesLine, TempTrackingSpecification, false, true);

        // [WHEN] post Output Journal for Item from Production Order with Tracking Specification with required tracking data
        CreateAndPostOutputJournalWithTrackingSpecification(TempTrackingSpecification, SalesLine."No.", ProdOrderNo);

        // [THEN] Provided by User Tracking Specification is transferred to Sales Order via Transfer Order
        VerifyTrackingSpecification(
          TempTrackingSpecification, DATABASE::"Sales Line", SalesLine."Document Type"::Order.AsInteger(),
          SalesLine."Document No.", '', 0, SalesLine."Line No.", -1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SynchronizeTransferOutboundToInboundItemTrackingSNAndLot()
    var
        SalesLine: Record "Sales Line";
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        ProdOrderNo: Code[20];
    begin
        // [FEATURE] [Item Tracking]
        // [SCENARIO 381007] Synchronize Transfer Outbound To Inbound Item Tracking for SN and Lot Specific Tracking
        Initialize();

        // [GIVEN] Sales Order as Demand and released Production Order as Supply at different Locations reserved one to another via Transfer Order
        ProdOrderNo := CreateSOAsDemandAndPOAsSupplyAtDifferentLocations(SalesLine, TempTrackingSpecification, true, true);

        // [WHEN] post Output Journal for Item from Production Order with Tracking Specification with required tracking data
        CreateAndPostOutputJournalWithTrackingSpecification(TempTrackingSpecification, SalesLine."No.", ProdOrderNo);

        // [THEN] Provided by User Tracking Specification is transferred to Sales Order via Transfer Order
        VerifyTrackingSpecification(
          TempTrackingSpecification, DATABASE::"Sales Line", SalesLine."Document Type"::Order.AsInteger(),
          SalesLine."Document No.", '', 0, SalesLine."Line No.", -1);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesPageHandler,ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure SynchronizeTransferOutboundToInboundOnRegisteringWhsePick()
    var
        Item: Record Item;
        LocationWhite: Record Location;
        LocationBlue: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        TransferHeader: Record "Transfer Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [FEATURE] [Item Tracking] [Warehouse Pick]
        // [SCENARIO 216549] Transfer Receipt can be posted if "Qty. to Handle" < Quantity on Item Tracking Lines for Transfer Shipment from location set up for directed put-away and pick.
        Initialize();

        // [GIVEN] Lot-tracked item.
        CreateTrackedItem(Item, false, true, false, true);

        // [GIVEN] Directed put-away and pick location "W", simple location "B".
        LibraryWarehouse.CreateFullWMSLocation(LocationWhite, 2);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationWhite.Code, true);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationBlue);

        // [GIVEN] The item is in inventory on location "W".
        UpdateTrackedInventoryOnFullWMSLocation(LocationWhite.Code, Item."No.", LibraryRandom.RandIntInRange(20, 40));

        // [GIVEN] Transfer Order from "W" to "B" for 1 pc of the item.
        // [GIVEN] Quantity = 1, but "Qty. to Handle" = 0 on item tracking line.
        CreateAndReleaseTransferOrderWithItemTracking(TransferHeader, Item."No.", LocationWhite.Code, LocationBlue.Code);

        // [GIVEN] Warehouse shipment from "W" is created in the transfer order.
        // [GIVEN] Warehouse pick is created and registered from the warehouse shipment.
        // [GIVEN] The warehouse shipment is posted.
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);
        WarehouseShipmentHeader.Get(
          LibraryWarehouse.FindWhseShipmentNoBySourceDoc(DATABASE::"Transfer Line", 0, TransferHeader."No."));
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        FindWarehouseActivityLine(WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, TransferHeader."No.");
        WarehouseActivityHeader.Get(WarehouseActivityHeader.Type::Pick, WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // [WHEN] Post the transfer receipt to "B".
        LibraryInventory.PostTransferHeader(TransferHeader, false, true);

        // [THEN] The item is transferred to "B".
        Item.SetRange("Location Filter", LocationBlue.Code);
        Item.CalcFields(Inventory);
        Item.TestField(Inventory, 1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SynchronizeTransferOutboundToInboundOnPostingInvtPick()
    var
        Item: Record Item;
        LocationSilver: Record Location;
        LocationBlue: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        TransferHeader: Record "Transfer Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseRequest: Record "Warehouse Request";
        LotNo: Code[50];
    begin
        // [FEATURE] [Item Tracking] [Inventory Pick]
        // [SCENARIO 216549] Transfer Receipt can be posted if "Qty. to Handle" < Quantity on Item Tracking Lines for Transfer Shipment from location set up for required inventory pick.
        Initialize();

        // [GIVEN] Lot-tracked item.
        CreateTrackedItem(Item, false, true, false, true);

        // [GIVEN] Location "S" with mandatory bin and required pick, simple location "B".
        LibraryWarehouse.CreateLocationWMS(LocationSilver, true, false, true, false, false);
        LibraryWarehouse.CreateNumberOfBins(LocationSilver.Code, '', '', 3, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationSilver.Code, false);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationBlue);

        // [GIVEN] The item is in inventory on location "S".
        LotNo := LibraryUtility.GenerateGUID();
        UpdateTrackedInventoryOnWMSLocation(LocationSilver.Code, Item."No.", LotNo, LibraryRandom.RandIntInRange(20, 40));

        // [GIVEN] Transfer Order from "S" to "B" for 1 pc of the item.
        // [GIVEN] Quantity = 1, but "Qty. to Handle" = 0 on item tracking line.
        CreateAndReleaseTransferOrderWithItemTracking(TransferHeader, Item."No.", LocationSilver.Code, LocationBlue.Code);

        // [GIVEN] Inventory Pick from "W" is created in the transfer order.
        // [GIVEN] The inventory pick is posted together with the transfer shipment.
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseRequest."Source Document"::"Outbound Transfer", TransferHeader."No.", false, true, false);
        FindWarehouseActivityLine(WarehouseActivityLine, WarehouseActivityLine."Activity Type"::"Invt. Pick", TransferHeader."No.");
        WarehouseActivityLine.AutofillQtyToHandle(WarehouseActivityLine);
        WarehouseActivityLine.ModifyAll("Lot No.", LotNo);
        WarehouseActivityHeader.Get(WarehouseActivityHeader.Type::"Invt. Pick", WarehouseActivityLine."No.");
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // [WHEN] Post the transfer receipt to "B".
        LibraryInventory.PostTransferHeader(TransferHeader, false, true);

        // [THEN] The item is transferred to "B".
        Item.SetRange("Location Filter", LocationBlue.Code);
        Item.CalcFields(Inventory);
        Item.TestField(Inventory, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateShipmentDateTrackingEntryDateConflictDateCanBeChanged()
    var
        Item: Record Item;
        Location: array[3] of Record Location;
        SKU: array[2] of Record "Stockkeeping Unit";
        SalesLine: Record "Sales Line";
        TransferLine: Record "Transfer Line";
    begin
        // [FEATURE] [Sales] [Shipment Date] [Date Conflict]
        // [SCENARIO 267780] Changing shipment date in transfer order to a later date is allowed when there is a tracking reservation entry between transfer and sale, and the date change results in date conflict

        Initialize();

        // [GIVEN] Item "I" with two stockkeeping units: "SKU1" on location "L1", and "SKU2" on "L2"
        LibraryInventory.CreateItem(Item);

        // [GIVEN] "SKU1" is set up to be replenished by transfer from location "L2", reordering policy is "Lot-for-Lot"
        CreateLocationsChain(Location[2], Location[1], Location[3]);
        CreateSKUWithPlanningParameters(
          SKU[1], Item."No.", Location[1].Code, SKU[1]."Replenishment System"::Transfer, Location[2].Code,
          SKU[1]."Reordering Policy"::"Lot-for-Lot");

        // [GIVEN] "SKU2" is replenished via purchase, reordering policy is "Order"
        CreateSKUWithPlanningParameters(
          SKU[2], Item."No.", Location[2].Code, SKU[2]."Replenishment System"::Purchase, '', SKU[2]."Reordering Policy"::Order);

        // [GIVEN] Sales order for item "I" on location "L1", shipment date = 08.02.2020
        CreateDemandFromSalesOrderLineQtyOne(SalesLine, Item."No.", Location[1].Code, LibraryRandom.RandDateFromInRange(WorkDate(), 10, 20));

        // [GIVEN] Calculate and carry out requisition plan
        // [GIVEN] Two orders are created: purchase on location "L2" and transfer from "L2" to "L1"
        // [GIVEN] Purchase is reserved for the outbound transfer, inbound transfer is linked to the sales order via a tracking entry
        Item.SetRecFilter();
        CalcRegPlanAndCarryOut(Item, CalcDate('<1M>', WorkDate()));
        FindTransferLine(TransferLine, Item."No.");

        // [WHEN] Change the shipment date on the transfer line from 08.02.2020 to 10.02.2020
        TransferLine.Validate("Shipment Date", SalesLine."Shipment Date" + 1);

        // [THEN] Receipt date is updated respectively. No date conflict warning is raised
        TransferLine.TestField("Receipt Date", TransferLine."Shipment Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateShipmentDateReservationDateConflictUpdateError()
    var
        Item: Record Item;
        Location: array[3] of Record Location;
        SKU: array[2] of Record "Stockkeeping Unit";
        SalesLine: Record "Sales Line";
        TransferLine: Record "Transfer Line";
    begin
        // [FEATURE] [Sales] [Shipment Date] [Date Conflict]
        // [SCENARIO 267780] Changing shipment date in transfer order to a later date is not allowed when there is reservation between transfer and sale, and the date change results in date conflict

        Initialize();

        // [GIVEN] Item "I" with two stockkeeping units: "SKU1" on location "L1", and "SKU2" on "L2"
        LibraryInventory.CreateItem(Item);
        CreateLocationsChain(Location[2], Location[1], Location[3]);

        // [GIVEN] "SKU1" is set up to be replenished by transfer from location "L2", reordering policy is "Order"
        CreateSKUWithPlanningParameters(
          SKU[1], Item."No.", Location[1].Code, SKU[1]."Replenishment System"::Transfer, Location[2].Code, SKU[1]."Reordering Policy"::Order);

        // [GIVEN] "SKU2" is replenished via purchase, reordering policy is "Order"
        CreateSKUWithPlanningParameters(
          SKU[2], Item."No.", Location[2].Code, SKU[2]."Replenishment System"::Purchase, '', SKU[2]."Reordering Policy"::Order);

        // [GIVEN] Sales order for item "I" on location "L1", shipment date = 08.02.2020
        CreateDemandFromSalesOrderLineQtyOne(SalesLine, Item."No.", Location[1].Code, LibraryRandom.RandDateFromInRange(WorkDate(), 10, 20));

        // [GIVEN] Calculate and carry out requisition plan
        // [GIVEN] Two orders are created: purchase on location "L2" and transfer from "L2" to "L1"
        // [GIVEN] Purchase is reserved for the outbound transfer, inbound transfer is reserved for the sales order
        Item.SetRecFilter();
        CalcRegPlanAndCarryOut(Item, CalcDate('<1M>', WorkDate()));
        FindTransferLine(TransferLine, Item."No.");

        // [WHEN] Change the shipment date on the transfer line from 08.02.2020 to 10.02.2020
        asserterror TransferLine.Validate("Shipment Date", SalesLine."Shipment Date" + 1);

        // [THEN] Error message is raised reading that the change results in a date conflict
        Assert.ExpectedError(ExpectedDateConfclictErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferLineChangeShipmentDateFailsWithReservation()
    var
        TransferLine: Record "Transfer Line";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
    begin
        // [FEATURE] [UT] [Purchase] [Shipment Date] [Date Conflict]
        // [SCENARIO 267780] When reservation exists for a transfer line, updating the shipment date is not allowed if the new date leads to a date conflict in reservation

        Initialize();

        MockPurchaseLine(PurchaseLine, WorkDate(), LibraryUtility.GenerateGUID());
        MockTransferLine(TransferLine, PurchaseLine."No.", WorkDate(), WorkDate());

        ReservationEntry."Entry No." := LibraryUtility.GetNewRecNo(ReservationEntry, ReservationEntry.FieldNo("Entry No."));
        MockReservationEntry(
          ReservationEntry,
          PurchaseLine."No.", false, DATABASE::"Transfer Line", 0, TransferLine."Document No.",
          TransferLine."Line No.", -1, ReservationEntry."Reservation Status"::Reservation, WorkDate());
        MockReservationEntry(
          ReservationEntry,
          PurchaseLine."No.", true, DATABASE::"Purchase Line", PurchaseLine."Document Type".AsInteger(), PurchaseLine."Document No.",
          PurchaseLine."Line No.", 1, ReservationEntry."Reservation Status"::Reservation, WorkDate());

        asserterror TransferLine.Validate("Shipment Date", TransferLine."Shipment Date" + 1);
        Assert.ExpectedError(ExpectedDateConfclictErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferLineChangeShipmentDateSucceedsWithTracking()
    var
        TransferLine: Record "Transfer Line";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        Item: Record Item;
    begin
        // [FEATURE] [UT] [Purchase] [Shipment Date] [Date Conflict]
        // [SCENARIO 267780] When item tracking record exists for a transfer line, updating the shipment date is allowed if the new date leads to a date conflict with linked supply

        Initialize();

        LibraryInventory.CreateItem(Item);
        MockPurchaseLine(PurchaseLine, WorkDate(), Item."No.");
        MockTransferLine(TransferLine, Item."No.", WorkDate(), WorkDate());

        ReservationEntry."Entry No." := LibraryUtility.GetNewRecNo(ReservationEntry, ReservationEntry.FieldNo("Entry No."));
        MockReservationEntry(
          ReservationEntry,
          Item."No.", false, DATABASE::"Transfer Line", 0, TransferLine."Document No.", TransferLine."Line No.", -1,
          ReservationEntry."Reservation Status"::Tracking, WorkDate());
        MockReservationEntry(
          ReservationEntry,
          Item."No.", true, DATABASE::"Purchase Line", PurchaseLine."Document Type".AsInteger(), PurchaseLine."Document No.", PurchaseLine."Line No.", -1,
          ReservationEntry."Reservation Status"::Tracking, WorkDate());

        TransferLine.Validate("Shipment Date", TransferLine."Shipment Date" + 1);
        TransferLine.TestField("Receipt Date", TransferLine."Shipment Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferLineChangeReceiptDateFailsWithReservation()
    var
        TransferLine: Record "Transfer Line";
        SalesLine: Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
    begin
        // [FEATURE] [UT] [Sales] [Shipment Date] [Date Conflict]
        // [SCENARIO 267780] When reservation exists for a transfer line, updating the receipt date is not allowed if the new date leads to a date conflict in reservation

        Initialize();

        MockSalesLine(SalesLine, WorkDate(), LibraryUtility.GenerateGUID());
        MockTransferLine(TransferLine, SalesLine."No.", WorkDate(), WorkDate());

        ReservationEntry."Entry No." := LibraryUtility.GetNewRecNo(ReservationEntry, ReservationEntry.FieldNo("Entry No."));
        MockReservationEntry(
          ReservationEntry,
          SalesLine."No.", false, DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.",
          -1, ReservationEntry."Reservation Status"::Reservation, WorkDate());
        MockReservationEntry(
          ReservationEntry,
          SalesLine."No.", true, DATABASE::"Transfer Line", 1, TransferLine."Document No.", TransferLine."Line No.", 1,
          ReservationEntry."Reservation Status"::Reservation, WorkDate());

        asserterror TransferLine.Validate("Receipt Date", TransferLine."Receipt Date" + 1);
        Assert.ExpectedError(ExpectedDateConfclictErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferLineChangeReceiptDateSucceedsWithTracking()
    var
        TransferLine: Record "Transfer Line";
        SalesLine: Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
        Item: Record Item;
    begin
        // [FEATURE] [UT] [Sales] [Shipment Date] [Date Conflict]
        // [SCENARIO 267780] When item tracking record exists for a transfer line, updating the receipt date is allowed if the new date leads to a date conflict with linked demand

        Initialize();

        LibraryInventory.CreateItem(Item);
        MockSalesLine(SalesLine, WorkDate(), Item."No.");
        MockTransferLine(TransferLine, Item."No.", WorkDate(), WorkDate());

        ReservationEntry."Entry No." := LibraryUtility.GetNewRecNo(ReservationEntry, ReservationEntry.FieldNo("Entry No."));
        MockReservationEntry(
          ReservationEntry,
          Item."No.", false, DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.",
          -1, ReservationEntry."Reservation Status"::Tracking, WorkDate());
        MockReservationEntry(
          ReservationEntry,
          Item."No.", true, DATABASE::"Transfer Line", 1, TransferLine."Document No.", TransferLine."Line No.", 1,
          ReservationEntry."Reservation Status"::Tracking, WorkDate());

        TransferLine.Validate("Receipt Date", TransferLine."Receipt Date" + 1);
        TransferLine.TestField("Shipment Date", TransferLine."Receipt Date");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SynchronizeItemTrackingFromInvtPickToTransferOrderWithReservation()
    var
        Item: Record Item;
        LocationSilver: Record Location;
        LocationBlue: Record Location;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ReservationEntry: Record "Reservation Entry";
        LotNo: Code[50];
    begin
        // [FEATURE] [Item Tracking] [Inventory Pick]
        // [SCENARIO 271087] When you set item tracking on inventory pick line and post it in order to ship a transfer, the item tracking is synchronized with the inbound transfer, which in its turn, is reserved for a sales order.
        Initialize();

        // [GIVEN] Lot-tracked item.
        CreateTrackedItem(Item, false, true, false, true);
        LotNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Location "Silver" set up for inventory pick.
        // [GIVEN] Location "Blue".
        CreateLocationSetUpForInvtPickPutaway(LocationSilver);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationBlue);

        // [GIVEN] 200 pcs of the item are in stock on "Silver".
        UpdateTrackedInventoryOnWMSLocation(LocationSilver.Code, Item."No.", LotNo, LibraryRandom.RandIntInRange(100, 200));

        // [GIVEN] Transfer order for 100 pcs from "Silver" to "Blue".
        CreateAndReleaseTransferOrder(
          TransferHeader, TransferLine, LocationSilver.Code, LocationBlue.Code, Item."No.", LibraryRandom.RandIntInRange(50, 100));

        // [GIVEN] A sales order from location "Blue" for 20 pcs.
        // [GIVEN] The sales is reserved from the inbound transfer.
        CreateSalesOrderReservedFromInboundTransfer(SalesLine, TransferLine, LibraryRandom.RandInt(20));

        // [WHEN] Create inventory pick for 100 pcs, define the lot no. = "L" on the pick line and post it in order to ship the transfer.
        CreateAndPostInventoryPickFromOutboundTransfer(WarehouseActivityLine, TransferHeader."No.", TransferLine.Quantity, LotNo);
        // [THEN] The item tracking is pushed to the inbound transfer.
        ReservationEntry.SetSourceFilter(DATABASE::"Transfer Line", 1, TransferLine."Document No.", -1, true);
        ReservationEntry.SetRange("Lot No.", LotNo);
        ReservationEntry.CalcSums(Quantity);
        ReservationEntry.TestField(Quantity, TransferLine.Quantity);

        // [WHEN] Continue the test - post the transfer receipt on "Blue".
        TransferHeader.Find();
        LibraryInventory.PostTransferHeader(TransferHeader, false, true);

        // [THEN] The item tracking for the inbound transfer is deleted.
        Assert.RecordIsEmpty(ReservationEntry);
        // [THEN] The sales order is now reserved from the inventory.
        ReservationEntry.Reset();
        ReservationEntry.SetSourceFilter(DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.", true);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField(Quantity, -SalesLine.Quantity);
        ReservationEntry.Reset();
        ReservationEntry.SetRange("Entry No.", ReservationEntry."Entry No.");
        ReservationEntry.SetRange(Positive, true);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField("Source Type", DATABASE::"Item Ledger Entry");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostingInvtPutawayForInboundTransferWithItemTrackingAndReservation()
    var
        Item: Record Item;
        LocationSilver: Record Location;
        LocationBlue: Record Location;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ReservationEntry: Record "Reservation Entry";
        LotNo: Code[50];
    begin
        // [FEATURE] [Item Tracking] [Inventory Pick]
        // [SCENARIO 271087] When you set item tracking on inventory put-away and post it in order to receive a transfer, which in its turn, is reserved for a sales order, the tracking for the transfer is deleted, and the sales is reserved from inventory.
        Initialize();

        // [GIVEN] Lot-tracked item.
        CreateTrackedItem(Item, false, true, false, true);
        LotNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Location "Blue".
        // [GIVEN] Location "Silver" set up for inventory pick.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationBlue);
        CreateLocationSetUpForInvtPickPutaway(LocationSilver);

        // [GIVEN] 200 pcs of the item are in stock on "Blue".
        UpdateTrackedInventory(LocationBlue.Code, '', Item."No.", LotNo, LibraryRandom.RandIntInRange(100, 200));

        // [GIVEN] Transfer order for 100 pcs from "Blue" to "Silver".
        CreateAndReleaseTransferOrder(
          TransferHeader, TransferLine, LocationBlue.Code, LocationSilver.Code, Item."No.", LibraryRandom.RandIntInRange(50, 100));

        // [GIVEN] A sales order from location "Silver" for 20 pcs.
        // [GIVEN] The sales is reserved from the inbound transfer.
        CreateSalesOrderReservedFromInboundTransfer(SalesLine, TransferLine, LibraryRandom.RandInt(20));

        // [GIVEN] Set lot no. = "L" on the outbound transfer and post the shipment.
        LibraryVariableStorage.Enqueue(ItemTrackingOption::AssignLotNo);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(TransferLine.Quantity);
        TransferLine.OpenItemTrackingLines("Transfer Direction"::Outbound);
        LibraryInventory.PostTransferHeader(TransferHeader, true, false);

        // [WHEN] Create inventory put-away for 90 pcs, define the lot no. = "L" and post it in order to receive the transfer.
        CreateAndPostInventoryPutawayFromInboundTransfer(
          WarehouseActivityLine, TransferHeader."No.", LocationSilver.Code, TransferLine.Quantity - LibraryRandom.RandInt(10), LotNo);
        // [THEN] Item tracking for not yet posted 10 pcs is left for the inbound transfer.
        ReservationEntry.SetSourceFilter(DATABASE::"Transfer Line", 1, TransferLine."Document No.", -1, true);
        ReservationEntry.SetRange("Lot No.", LotNo);
        ReservationEntry.CalcSums(Quantity);
        ReservationEntry.TestField(Quantity, WarehouseActivityLine.Quantity - WarehouseActivityLine."Qty. to Handle");
        // [THEN] The sales order is now reserved from the inventory.
        ReservationEntry.Reset();
        ReservationEntry.SetSourceFilter(DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.", true);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField(Quantity, -SalesLine.Quantity);
        ReservationEntry.Reset();
        ReservationEntry.SetRange("Entry No.", ReservationEntry."Entry No.");
        ReservationEntry.SetRange(Positive, true);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField("Source Type", DATABASE::"Item Ledger Entry");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SynchronizeItemTrackingFromReservedAndPickedOutboundTransferToInbound()
    var
        Item: Record Item;
        LocationSilver: Record Location;
        LocationBlue: Record Location;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ReservationEntry: Record "Reservation Entry";
        LotNo: Code[50];
        Qty: Decimal;
    begin
        // [FEATURE] [Item Tracking] [Inventory Pick]
        // [SCENARIO 271087] When you set item tracking on inventory pick line for the outbound transfer reserved from the inventory, and post the inventory pick, the item tracking is pushed to the inbound size of the transfer.
        Initialize();

        // [GIVEN] Lot-tracked item.
        CreateTrackedItem(Item, false, true, false, true);
        LotNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Location "Silver" set up for inventory pick.
        // [GIVEN] Location "Blue".
        CreateLocationSetUpForInvtPickPutaway(LocationSilver);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationBlue);

        // [GIVEN] 200 pcs of the item are in stock on "Silver".
        Qty := LibraryRandom.RandIntInRange(100, 200);
        UpdateTrackedInventoryOnWMSLocation(LocationSilver.Code, Item."No.", LotNo, Qty);

        // [GIVEN] Transfer order for 100 pcs from "Silver" to "Blue".
        CreateAndReleaseTransferOrder(TransferHeader, TransferLine, LocationSilver.Code, LocationBlue.Code, Item."No.", Qty);

        // [GIVEN] The outbound transfer is reserved from the inventory.
        AutoReserveTransferLine(TransferLine, TransferLine."Shipment Date", "Transfer Direction"::Outbound);

        // [WHEN] Create inventory pick for 90 pcs, define the lot no. = "L" on the pick line and post it in order to ship the transfer.
        CreateAndPostInventoryPickFromOutboundTransfer(
          WarehouseActivityLine, TransferHeader."No.", Qty - LibraryRandom.RandInt(10), LotNo);
        // [THEN] Item tracking for 90 pcs is assigned to the inbound transfer.
        ReservationEntry.SetSourceFilter(DATABASE::"Transfer Line", 1, TransferLine."Document No.", -1, true);
        ReservationEntry.SetRange("Lot No.", LotNo);
        ReservationEntry.CalcSums(Quantity);
        ReservationEntry.TestField(Quantity, WarehouseActivityLine."Qty. to Handle");
        // [THEN] Not shipped 10 pcs are still reserved from the inventory.
        ReservationEntry.Reset();
        ReservationEntry.SetSourceFilter(DATABASE::"Transfer Line", 0, TransferLine."Document No.", -1, true);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField(Quantity, -(WarehouseActivityLine.Quantity - WarehouseActivityLine."Qty. to Handle"));
        ReservationEntry.Reset();
        ReservationEntry.SetRange("Entry No.", ReservationEntry."Entry No.");
        ReservationEntry.SetRange(Positive, true);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField("Source Type", DATABASE::"Item Ledger Entry");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SynchnorizeItemTrackingAssignedOnTransferLineAndPartiallyPostedInvtPickToInbound()
    var
        Item: Record Item;
        LocationSilver: Record Location;
        LocationBlue: Record Location;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ReservationEntry: Record "Reservation Entry";
        LotNo: Code[50];
    begin
        // [FEATURE] [Item Tracking] [Inventory Pick]
        // [SCENARIO 271087] When you set item tracking on transfer line, create an inventory pick, decrease the quantity to handle and post the inventory pick, the item tracking is synchronized with the inbound transfer.
        Initialize();

        // [GIVEN] Lot-tracked item.
        CreateTrackedItem(Item, false, true, false, true);
        LotNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Location "Silver" set up for inventory pick.
        // [GIVEN] Location "Blue".
        CreateLocationSetUpForInvtPickPutaway(LocationSilver);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationBlue);

        // [GIVEN] 200 pcs of the item are in stock on "Silver".
        UpdateTrackedInventoryOnWMSLocation(LocationSilver.Code, Item."No.", LotNo, LibraryRandom.RandIntInRange(100, 200));

        // [GIVEN] Transfer order for 100 pcs from "Silver" to "Blue".
        CreateAndReleaseTransferOrder(
          TransferHeader, TransferLine, LocationSilver.Code, LocationBlue.Code, Item."No.", LibraryRandom.RandIntInRange(50, 100));

        // [GIVEN] A sales order from location "Blue" for 20 pcs.
        // [GIVEN] The sales is reserved from the inbound transfer without lot no. specified.
        CreateSalesOrderReservedFromInboundTransfer(SalesLine, TransferLine, LibraryRandom.RandInt(20));

        // [GIVEN] Open item tracking for the outbound transfer and assign lot no. = "L".
        LibraryVariableStorage.Enqueue(ItemTrackingOption::AssignLotNo);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(TransferLine.Quantity);
        TransferLine.OpenItemTrackingLines("Transfer Direction"::Outbound);

        // [WHEN] Create inventory pick for 90 pcs post it in order to ship the transfer.
        CreateAndPostInventoryPickFromOutboundTransfer(
          WarehouseActivityLine, TransferHeader."No.", TransferLine.Quantity - LibraryRandom.RandInt(10), LotNo);
        // [THEN] Item tracking for 10 pcs is assigned to the outbound side of the transfer.
        ReservationEntry.SetSourceFilter(DATABASE::"Transfer Line", 0, TransferLine."Document No.", -1, true);
        ReservationEntry.SetRange("Lot No.", LotNo);
        ReservationEntry.CalcSums(Quantity);
        ReservationEntry.TestField(Quantity, -(WarehouseActivityLine.Quantity - WarehouseActivityLine."Qty. to Handle"));
        // [THEN] Item tracking for 80 pcs is assigned to the inbound side (total 100 pcs tracked minus 20 pcs in the reservation for the sales).
        ReservationEntry.SetSourceFilter(DATABASE::"Transfer Line", 1, TransferLine."Document No.", -1, true);
        ReservationEntry.SetRange("Lot No.", LotNo);
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Surplus);
        ReservationEntry.CalcSums(Quantity);
        ReservationEntry.TestField(Quantity, TransferLine.Quantity - SalesLine.Quantity);
        // [THEN] The sales order is now reserved from the lot-tracked inbound transfer.
        ReservationEntry.Reset();
        ReservationEntry.SetSourceFilter(DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.", true);
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Reservation);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField(Quantity, -SalesLine.Quantity);
        ReservationEntry.Reset();
        ReservationEntry.SetRange("Entry No.", ReservationEntry."Entry No.");
        ReservationEntry.SetRange(Positive, true);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField("Source Type", DATABASE::"Transfer Line");
        ReservationEntry.TestField("Lot No.", LotNo);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostingInvtPickFailsOnTrackingMismatchBetweenTransferLineAndInvtPickLine()
    var
        Item: Record Item;
        LocationSilver: Record Location;
        LocationBlue: Record Location;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WarehouseRequest: Record "Warehouse Request";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LotNo: Code[50];
        Qty: Decimal;
        TrackedQty: Decimal;
    begin
        // [FEATURE] [Item Tracking] [Inventory Pick]
        // [SCENARIO 271087] When you set item tracking on inventory pick greater than you earlier set on the transfer line, the posting succeeds for the tracked quantity.
        Initialize();

        // [GIVEN] Lot-tracked item.
        CreateTrackedItem(Item, false, true, false, true);
        LotNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Location "Silver" set up for inventory pick.
        // [GIVEN] Location "Blue".
        CreateLocationSetUpForInvtPickPutaway(LocationSilver);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationBlue);

        // [GIVEN] 200 pcs of the item are in stock on "Silver".
        Qty := LibraryRandom.RandIntInRange(100, 200);
        TrackedQty := Qty - LibraryRandom.RandIntInRange(20, 40);
        UpdateTrackedInventoryOnWMSLocation(LocationSilver.Code, Item."No.", LotNo, Qty);

        // [GIVEN] Transfer order for 200 pcs from "Silver" to "Blue".
        CreateAndReleaseTransferOrder(TransferHeader, TransferLine, LocationSilver.Code, LocationBlue.Code, Item."No.", Qty);

        // [GIVEN] Open item tracking for the outbound transfer and assign lot no. = "L" and "Qty. to Handle" = 160 pcs.
        LibraryVariableStorage.Enqueue(ItemTrackingOption::AssignLotNo);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(TrackedQty);
        TransferLine.OpenItemTrackingLines("Transfer Direction"::Outbound);
        // [GIVEN] Create inventory pick, define lot no. = "L" and "Qty. to Handle" = 161 pcs.
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseRequest."Source Document"::"Outbound Transfer", TransferHeader."No.", false, true, false);
        FindWarehouseActivityLine(WarehouseActivityLine, WarehouseActivityLine."Activity Type"::"Invt. Pick", TransferHeader."No.");
        WarehouseActivityLine.Validate("Qty. to Handle", TrackedQty);
        WarehouseActivityLine.Validate("Lot No.", LotNo);
        WarehouseActivityLine.Modify(true);

        WarehouseActivityLine.Next();
        WarehouseActivityLine.Validate("Qty. to Handle", 1);
        WarehouseActivityLine.Validate("Lot No.", LotNo);
        WarehouseActivityLine.Modify(true);

        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");

        // [WHEN] Post the inventory pick in order to ship the transfer.
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // [THEN] 161 pcs on the transfer line are shipped.
        TransferLine.Find();
        TransferLine.TestField("Quantity Shipped", TrackedQty + 1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure InsertItemTrackingOnPurchLineManuallyInsertsTrackingInTransferViaOrderToOrderBinding()
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        LotNo: Code[50];
        LotQty: Decimal;
    begin
        // [FEATURE] [Purchase] [Item Tracking] [Order-to-Order Binding]
        // [SCENARIO 283223] When a user inserts new item tracking line on purchase line planned to supply transfer, the new item tracking is pushed to the inbound transfer.
        Initialize();

        // [GIVEN] Lot-tracked item "I" with Reordering Policy = "Order".
        CreateLotTrackedItemForPlanning(Item);

        // [GIVEN] Transfer order for 100 pcs of item "I".
        CreateTransferOrder(TransferHeader, TransferLine, Item."No.", LibraryRandom.RandIntInRange(50, 100));

        // [GIVEN] Calculate regenerative plan in planning worksheet to supply the transfer order.
        Item.SetRecFilter();
        Item.SetRange("Location Filter", TransferHeader."Transfer-from Code");
        CalcRegPlanAndCarryOut(Item, WorkDate());

        // [GIVEN] A new purchase order is created after carrying out action in the planning worksheet.
        FindPurchaseLine(PurchaseLine, Item."No.");

        LotNo := LibraryUtility.GenerateGUID();
        LotQty := PurchaseLine.Quantity;
        LibraryVariableStorage.Enqueue(ItemTrackingOption::AssignLotNo);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(LotQty);

        // [WHEN] Insert item tracking on the purchase line. Lot No. = "L", Quantity = 100.
        PurchaseLine.OpenItemTrackingLines();

        // [THEN] The item tracking on purchase line is pushed to the inbound transfer (via outbound transfer).
        // [THEN] Lot No. = "L", quantity = 100.
        ReservationEntry.SetSourceFilter(
          DATABASE::"Transfer Line", Direction::Inbound, TransferLine."Document No.", TransferLine."Line No.", false);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField("Lot No.", LotNo);
        ReservationEntry.TestField(Quantity, LotQty);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InsertItemTrackingOnPurchLineByCodeInsertsTrackingInTransferViaOrderToOrderBinding()
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        PurchaseLine: Record "Purchase Line";
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        SourceTrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
        PurchLineReserve: Codeunit "Purch. Line-Reserve";
        ItemTrackingLines: Page "Item Tracking Lines";
        LotNo: Code[50];
        LotQty: Decimal;
    begin
        // [FEATURE] [Purchase] [Item Tracking] [Order-to-Order Binding]
        // [SCENARIO 283223] When the program inserts item tracking on purchase line planned to supply transfer, the new item tracking is pushed to the inbound transfer.
        Initialize();

        // [GIVEN] Lot-tracked item "I" with Reordering Policy = "Order".
        CreateLotTrackedItemForPlanning(Item);

        // [GIVEN] Transfer order for 100 pcs of item "I".
        CreateTransferOrder(TransferHeader, TransferLine, Item."No.", LibraryRandom.RandIntInRange(50, 100));

        // [GIVEN] Calculate regenerative plan in planning worksheet to supply the transfer order.
        Item.SetRecFilter();
        Item.SetRange("Location Filter", TransferHeader."Transfer-from Code");
        CalcRegPlanAndCarryOut(Item, WorkDate());

        // [GIVEN] A new purchase order is created after carrying out action in the planning worksheet.
        FindPurchaseLine(PurchaseLine, Item."No.");

        LotNo := LibraryUtility.GenerateGUID();
        LotQty := LibraryRandom.RandIntInRange(10, 20);
        TempTrackingSpecification.Init();
        TempTrackingSpecification."Entry No." += 1;
        TempTrackingSpecification.Validate("Lot No.", LotNo);
        TempTrackingSpecification.Validate("Quantity (Base)", LotQty);
        TempTrackingSpecification.Insert();

        // [WHEN] Invoke RegisterItemTrackingLines function in page 6510 to register a new item tracking line. Lot No. = "L", Quantity = 20.
        PurchLineReserve.InitFromPurchLine(SourceTrackingSpecification, PurchaseLine);
        ItemTrackingLines.RegisterItemTrackingLines(SourceTrackingSpecification, WorkDate(), TempTrackingSpecification);

        // [THEN] The item tracking on purchase line is pushed to the inbound transfer (via outbound transfer).
        // [THEN] Lot No. = "L", quantity = 20.
        ReservationEntry.SetSourceFilter(
          DATABASE::"Transfer Line", Direction::Inbound, TransferLine."Document No.", TransferLine."Line No.", false);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField("Lot No.", LotNo);
        ReservationEntry.TestField(Quantity, LotQty);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ModifyItemTrackingOnPurchLineModifiesTrackingInTransferViaOrderToOrderBinding()
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        LotNo: Code[50];
        LotQty: Decimal;
    begin
        // [FEATURE] [Purchase] [Item Tracking] [Order-to-Order Binding]
        // [SCENARIO 283223] When a user modifies existing item tracking line on purchase line planned to supply transfer, the changes are pushed to the inbound transfer.
        Initialize();

        // [GIVEN] Lot-tracked item "I" with Reordering Policy = "Order".
        CreateLotTrackedItemForPlanning(Item);

        // [GIVEN] Transfer order for 100 pcs of item "I".
        CreateTransferOrder(TransferHeader, TransferLine, Item."No.", LibraryRandom.RandIntInRange(50, 100));

        // [GIVEN] Calculate regenerative plan in planning worksheet to supply the transfer order.
        Item.SetRecFilter();
        Item.SetRange("Location Filter", TransferHeader."Transfer-from Code");
        CalcRegPlanAndCarryOut(Item, WorkDate());

        // [GIVEN] A new purchase order is created after carrying out action in the planning worksheet.
        FindPurchaseLine(PurchaseLine, Item."No.");

        // [GIVEN] Insert item tracking on the purchase line. Lot No. = "L", Quantity = 100.
        LotNo := LibraryUtility.GenerateGUID();
        LibraryVariableStorage.Enqueue(ItemTrackingOption::AssignLotNo);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(PurchaseLine.Quantity);
        PurchaseLine.OpenItemTrackingLines();

        LotQty := LibraryRandom.RandIntInRange(10, 20);
        LibraryVariableStorage.Enqueue(ItemTrackingOption::ChangeLotQty);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(LotQty);

        // [WHEN] Modify item tracking on the purchase line. New quantity = 20.
        PurchaseLine.OpenItemTrackingLines();

        // [THEN] The changes in item tracking on purchase line are pushed to the inbound transfer (via outbound transfer).
        // [THEN] Lot No. = "L", quantity = 20.
        ReservationEntry.SetSourceFilter(
          DATABASE::"Transfer Line", Direction::Inbound, TransferLine."Document No.", TransferLine."Line No.", false);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField("Lot No.", LotNo);
        ReservationEntry.TestField(Quantity, LotQty);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ConfirmCloseWithQtyZero')]
    [Scope('OnPrem')]
    procedure DeleteItemTrackingOnPurchLineDeletesTrackingInTransferViaOrderToOrderBinding()
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        LotNo: Code[50];
    begin
        // [FEATURE] [Purchase] [Item Tracking] [Order-to-Order Binding]
        // [SCENARIO 283223] When a user deletes existing item tracking line on purchase line planned to supply transfer, that deletes the item tracking in the inbound transfer.
        Initialize();

        // [GIVEN] Lot-tracked item "I" with Reordering Policy = "Order".
        CreateLotTrackedItemForPlanning(Item);

        // [GIVEN] Transfer order for 100 pcs of item "I".
        CreateTransferOrder(TransferHeader, TransferLine, Item."No.", LibraryRandom.RandIntInRange(50, 100));

        // [GIVEN] Calculate regenerative plan in planning worksheet to supply the transfer order.
        Item.SetRecFilter();
        Item.SetRange("Location Filter", TransferHeader."Transfer-from Code");
        CalcRegPlanAndCarryOut(Item, WorkDate());

        // [GIVEN] A new purchase order is created after carrying out action in the planning worksheet.
        FindPurchaseLine(PurchaseLine, Item."No.");

        // [GIVEN] Insert item tracking on the purchase line. Lot No. = "L", Quantity = 100.
        LotNo := LibraryUtility.GenerateGUID();
        LibraryVariableStorage.Enqueue(ItemTrackingOption::AssignLotNo);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(PurchaseLine.Quantity);
        PurchaseLine.OpenItemTrackingLines();

        LibraryVariableStorage.Enqueue(ItemTrackingOption::ChangeLotQty);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(0);

        // [WHEN] Clear item tracking on the purchase line.
        PurchaseLine.OpenItemTrackingLines();

        // [THEN] Item tracking in inbound transfer has been deleted.
        ReservationEntry.SetSourceFilter(
          DATABASE::"Transfer Line", Direction::Inbound, TransferLine."Document No.", TransferLine."Line No.", false);
        Assert.RecordIsEmpty(ReservationEntry);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DateConflictCheckWhenChangingReceiptDateOnReservedTransfer()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        SalesLine: Record "Sales Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
    begin
        // [FEATURE] [Date Conflict]
        // [SCENARIO 295798] Date Conflict check is performed when you change receipt date on active transfer line reserved for a demand.
        Initialize();

        LibraryInventory.CreateItem(Item);

        // [GIVEN] Transfer order from location "Blue" to "Red".
        CreateTransferOrder(TransferHeader, TransferLine, Item."No.", LibraryRandom.RandInt(100));

        // [GIVEN] The item is in inventory on location "Blue".
        LibraryInventory.CreateItemJournalLineInItemTemplate(
          ItemJournalLine, Item."No.", TransferHeader."Transfer-from Code", '', LibraryRandom.RandIntInRange(100, 200));
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Sales order on location "Red" is reserved from the inbound transfer.
        CreateSalesOrderReservedFromInboundTransfer(SalesLine, TransferLine, TransferLine.Quantity);

        // [WHEN] Move the receipt date on the transfer line to later than the shipment date.
        TransferLine.Find();
        asserterror TransferLine.Validate("Receipt Date", LibraryRandom.RandDateFromInRange(TransferLine."Receipt Date", 30, 60));

        // [THEN] Date Conflict in reservation error message is thrown.
        Assert.ExpectedError(ExpectedDateConfclictErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DateConflictCheckWhenChangingReceiptDateAfterPostingTransferShipment()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        SalesLine: Record "Sales Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
    begin
        // [FEATURE] [Date Conflict]
        // [SCENARIO 295798] Date Conflict check is performed when you change receipt date on shipped transfer line reserved for a demand.
        Initialize();

        LibraryInventory.CreateItem(Item);

        // [GIVEN] Transfer order from location "Blue" to "Red".
        CreateTransferOrder(TransferHeader, TransferLine, Item."No.", LibraryRandom.RandInt(100));

        // [GIVEN] The item is in inventory on location "Blue".
        LibraryInventory.CreateItemJournalLineInItemTemplate(
          ItemJournalLine, Item."No.", TransferHeader."Transfer-from Code", '', LibraryRandom.RandIntInRange(100, 200));
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Sales order on location "Red" is reserved from the inbound transfer.
        CreateSalesOrderReservedFromInboundTransfer(SalesLine, TransferLine, TransferLine.Quantity);

        // [GIVEN] Ship the transfer order.
        LibraryInventory.PostTransferHeader(TransferHeader, true, false);

        // [WHEN] Move the receipt date on the transfer line to later than the shipment date.
        TransferLine.Find();
        asserterror TransferLine.Validate("Receipt Date", LibraryRandom.RandDateFromInRange(TransferLine."Receipt Date", 30, 60));

        // [THEN] Date Conflict in reservation error message is thrown.
        Assert.ExpectedError(ExpectedDateConfclictErr);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreateModalPageHandler,PostedPurchaseReceiptsModalPageHandler,PostedPurchaseReceiptLinesModalPageHandler')]
    [Scope('OnPrem')]
    procedure ItemTrackingOnTransferLineCopiedFromPostedRcptLine()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationInTransit: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ReservEntry: Record "Reservation Entry";
        Qty: Decimal;
    begin
        // [FEATURE] [Item Tracking] [Get Receipt Lines]
        // [SCENARIO 322980] Item Tracking is transferred from posted purchase receipt when you create a transfer line using "Get Receipt Line".
        Initialize();
        Qty := LibraryRandom.RandIntInRange(2, 5);

        // [GIVEN] Serial no.-tracked item.
        LibraryItemTracking.CreateSerialItem(Item);
        CreateLocationsChain(LocationFrom, LocationTo, LocationInTransit);

        // [GIVEN] Purchase order on location "From". Assign 5 serial nos. to the purchase line.
        // [GIVEN] Post the purchase receipt.
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', Item."No.", Qty, LocationFrom.Code, WorkDate());
        LibraryVariableStorage.Enqueue(ItemTrackingOption::AssignSerialNos);
        PurchaseLine.OpenItemTrackingLines();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Create transfer order from location "From" to location "To".
        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationInTransit.Code);

        // [WHEN] Invoke "Get Receipt Lines" function and select the posted receipt line.
        TransferHeader.GetReceiptLines();

        // [THEN] Transfer line is created.
        // [THEN] 5 serial nos. are assigned on the transfer line.
        FindTransferLine(TransferLine, Item."No.");
        ReservEntry.SetSourceFilter(DATABASE::"Transfer Line", 0, TransferLine."Document No.", TransferLine."Line No.", false);
        Assert.RecordCount(ReservEntry, Qty);
        ReservEntry.CalcSums(Quantity);
        ReservEntry.TestField(Quantity, -Qty);

        // [THEN] The item tracking is also pushed to the inbound transfer.
        ReservEntry.SetSourceFilter(DATABASE::"Transfer Line", 1, TransferLine."Document No.", TransferLine."Line No.", false);
        Assert.RecordCount(ReservEntry, Qty);
        ReservEntry.CalcSums(Quantity);
        ReservEntry.TestField(Quantity, Qty);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedPurchaseReceiptsModalPageHandler,PostedPurchaseReceiptLinesModalPageHandler')]
    [Scope('OnPrem')]
    procedure NoItemTrackingOnTransferLineIfPostedRcptLineHadNoTracking()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationInTransit: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ReservEntry: Record "Reservation Entry";
    begin
        // [FEATURE] [Item Tracking] [Get Receipt Lines]
        // [SCENARIO 322980] No reservation entries are created on transfer line, if the posted purchase receipt the transfer line was created from had no item tracking.
        Initialize();

        // [GIVEN] Item with disabled item tracking.
        LibraryInventory.CreateItem(Item);
        CreateLocationsChain(LocationFrom, LocationTo, LocationInTransit);

        // [GIVEN] Purchase order on location "From".
        // [GIVEN] Post the purchase receipt.
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '',
          Item."No.", LibraryRandom.RandInt(10), LocationFrom.Code, WorkDate());
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Create transfer order from location "From" to location "To".
        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationInTransit.Code);

        // [WHEN] Invoke "Get Receipt Lines" function and select the posted receipt line.
        TransferHeader.GetReceiptLines();

        // [THEN] Transfer line is created.
        // [THEN] No reservation entries are created for the new transfer line.
        FindTransferLine(TransferLine, Item."No.");
        ReservEntry.SetSourceFilter(DATABASE::"Transfer Line", 0, TransferLine."Document No.", TransferLine."Line No.", false);
        Assert.RecordIsEmpty(ReservEntry);
    end;

    [Test]
    procedure ReservationEntryNotModifiedWhenDeleteQtyToHandleOnWhsePickForTransferOutbound()
    var
        Item: Record Item;
        LocationWhite: Record Location;
        LocationBlue: Record Location;
        LocationTransit: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ReservationEntry: Record "Reservation Entry";
    begin
        // [FEATURE] [Warehouse Pick]
        // [SCENARIO 384945] Outbound Reservation Entry "Qty. to Handle (Base)" not modified for Transfer Order if "Qty. to Handle" was deleted on Warehouse Pick Lines when Item Tracking is not used
        Initialize();

        // [GIVEN] Item without Item Tracking
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Directed put-away and pick location "W", simple location "B", transit location "T".
        LibraryWarehouse.CreateFullWMSLocation(LocationWhite, 2);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationWhite.Code, true);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationBlue);
        LibraryWarehouse.CreateInTransitLocation(LocationTransit);

        // [GIVEN] 20 PCS of item is in inventory on location "W".
        LibraryWarehouse.UpdateInventoryOnLocationWithDirectedPutAwayAndPick(
          Item."No.", LocationWhite.Code, LibraryRandom.RandIntInRange(20, 40), false);

        // [GIVEN] Released Transfer Order from "W" to "B" through "T" for 10 pcs of the item, autoreserved.
        LibraryInventory.CreateTransferHeader(TransferHeader, LocationWhite.Code, LocationBlue.Code, LocationTransit.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", LibraryRandom.RandIntInRange(6, 10));
        AutoReserveTransferLine(TransferLine, TransferLine."Shipment Date", "Transfer Direction"::Outbound);
        LibraryInventory.ReleaseTransferOrder(TransferHeader);

        // [GIVEN] Warehouse shipment from "W" is created for the transfer order.
        // [GIVEN] Warehouse pick is created from the warehouse shipment.
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);
        WarehouseShipmentHeader.Get(
          LibraryWarehouse.FindWhseShipmentNoBySourceDoc(DATABASE::"Transfer Line", 0, TransferHeader."No."));
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        FindSetWarehouseActivityLine(WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, TransferHeader."No.");

        // [WHEN] Delete "Qty. to Handle" on warehouse pick lines
        WarehouseActivityLine.DeleteQtyToHandle(WarehouseActivityLine);

        // [THEN] "Qty. to Handle (Base)" = -10 on the Reservation Entry for the Transfer Order
        ReservationEntry.SetSourceFilter(
          DATABASE::"Transfer Line", Direction::Outbound, TransferLine."Document No.", TransferLine."Line No.", false);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField("Qty. to Handle (Base)", -TransferLine.Quantity);

    end;

    [Test]
    procedure CorrectTransferOutboundReservedOnWhsePickAndShipmentWithDeleteQtyToHandle()
    var
        Item: Record Item;
        LocationWhite: Record Location;
        LocationBlue: Record Location;
        LocationTransit: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        QtyToHandle: Decimal;
    begin
        // [FEATURE] [Warehouse Pick]
        // [SCENARIO 384945] Transfer Order has correct "Reserved Qty. Outbound" if "Qty. to Handle" was deleted and revalidated to partial qty on Warehouse Pick Lines for Whse. Shipment when Item Tracking is not used
        Initialize();

        // [GIVEN] Item without Item Tracking
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Directed put-away and pick location "W", simple location "B", transit location "T".
        LibraryWarehouse.CreateFullWMSLocation(LocationWhite, 2);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationWhite.Code, true);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationBlue);
        LibraryWarehouse.CreateInTransitLocation(LocationTransit);

        // [GIVEN] 20 PCS of item is in inventory on location "W".
        LibraryWarehouse.UpdateInventoryOnLocationWithDirectedPutAwayAndPick(
          Item."No.", LocationWhite.Code, LibraryRandom.RandIntInRange(20, 40), false);

        // [GIVEN] Released Transfer Order from "W" to "B" through "T" for 10 pcs of the item, autoreserved.
        LibraryInventory.CreateTransferHeader(TransferHeader, LocationWhite.Code, LocationBlue.Code, LocationTransit.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", LibraryRandom.RandIntInRange(6, 10));
        AutoReserveTransferLine(TransferLine, TransferLine."Shipment Date", "Transfer Direction"::Outbound);
        LibraryInventory.ReleaseTransferOrder(TransferHeader);

        // [GIVEN] Warehouse shipment from "W" is created for the transfer order.
        // [GIVEN] Warehouse pick is created from the warehouse shipment.
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);
        WarehouseShipmentHeader.Get(
          LibraryWarehouse.FindWhseShipmentNoBySourceDoc(DATABASE::"Transfer Line", 0, TransferHeader."No."));
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        FindSetWarehouseActivityLine(WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, TransferHeader."No.");
        WarehouseActivityHeader.Get(WarehouseActivityHeader.Type::Pick, WarehouseActivityLine."No.");

        // [GIVEN] "Qty. to Handle" deleted on the warehouse pick lines
        WarehouseActivityLine.DeleteQtyToHandle(WarehouseActivityLine);

        // [GIVEN] Warehouse pick registered with "Qty to Handle" = 3 PCS on the warehouse pick lines
        QtyToHandle := LibraryRandom.RandInt(5);
        UpdateQtyToHandleOnWarehouseActivityLines(WarehouseActivityLine, QtyToHandle);
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [WHEN] Post Warehouse Shipment for the Transfer Order
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // [THEN] "Reserved Quantity Outbnd." = 7 PCS on the Transfer Line
        TransferLine.CalcFields("Reserved Quantity Outbnd.");
        TransferLine.TestField("Reserved Quantity Outbnd.", TransferLine.Quantity - QtyToHandle);
    end;

    [Test]
    procedure CorrectTransferOutboundReservedOnWhsePickAndShipmentWithAdditionalReservation()
    var
        Item: Record Item;
        LocationWhite: Record Location;
        LocationBlue: Record Location;
        LocationTransit: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        QtyToHandle: Decimal;
    begin
        // [FEATURE] [Warehouse Pick]
        // [SCENARIO 384946] Transfer Line has correct "Reserved Qty. Outbound" and "Reserved Qty. Outbnd. (Base)" when doing Reservation From Inventory
        Initialize();

        // [GIVEN] Item without Item Tracking
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Directed put-away and pick location "W", simple location "B", transit location "T".
        LibraryWarehouse.CreateFullWMSLocation(LocationWhite, 2);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationWhite.Code, true);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationBlue);
        LibraryWarehouse.CreateInTransitLocation(LocationTransit);

        // [GIVEN] 20 PCS of item is in inventory on location "W".
        LibraryWarehouse.UpdateInventoryOnLocationWithDirectedPutAwayAndPick(
          Item."No.", LocationWhite.Code, LibraryRandom.RandIntInRange(20, 40), false);

        // [GIVEN] Released Transfer Order from "W" to "B" through "T" for 10 pcs of the item, autoreserved.
        LibraryInventory.CreateTransferHeader(TransferHeader, LocationWhite.Code, LocationBlue.Code, LocationTransit.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", LibraryRandom.RandIntInRange(6, 10));
        AutoReserveTransferLine(TransferLine, TransferLine."Shipment Date", "Transfer Direction"::Outbound);
        LibraryInventory.ReleaseTransferOrder(TransferHeader);

        // [GIVEN] Warehouse shipment from "W" is created for the transfer order.
        // [GIVEN] Warehouse pick is created from the warehouse shipment.
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);
        WarehouseShipmentHeader.Get(
          LibraryWarehouse.FindWhseShipmentNoBySourceDoc(DATABASE::"Transfer Line", 0, TransferHeader."No."));
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        FindSetWarehouseActivityLine(WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, TransferHeader."No.");
        WarehouseActivityHeader.Get(WarehouseActivityHeader.Type::Pick, WarehouseActivityLine."No.");

        // [GIVEN] "Qty. to Handle" deleted on the warehouse pick lines
        WarehouseActivityLine.DeleteQtyToHandle(WarehouseActivityLine);

        // [GIVEN] Warehouse pick registered with "Qty to Handle" = 3 PCS on the warehouse pick lines
        QtyToHandle := LibraryRandom.RandInt(5);
        UpdateQtyToHandleOnWarehouseActivityLines(WarehouseActivityLine, QtyToHandle);
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [GIVEN] Post Warehouse Shipment for the Transfer Order
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // [GIVEN] Add additional "Qty. to Ship" on Transfer Line and clear last error
        UpdateQtyToShipAndBaseOnTransferLine(TransferLine, 3, 3);
        ClearLastError();

        // [WHEN] Reserve from Inventory with Transfer Line having "Reserved Qty. Outbound" = 3 PCS and "Qty. to Ship" = 3 PCS
        TransferLine.ReserveFromInventory(TransferLine);

        // [THEN] No unexpected errors should happen durring Reservation from Inventory
        Assert.AreEqual('', GetLastErrorText, UnexpectedErr);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesLotPageHandler')]
    procedure VerifyPostingShipmentIsNotAllowedOnTransferOrderWithItemTrackingLinesAndPartialShipQty()
    var
        Item: Record Item;
        LocationWhite: Record Location;
        LocationBlue: Record Location;
        TransferHeader: Record "Transfer Header";
        LotNo, LotNo2 : Code[20];
    begin
        // [SCENARIO 462516] Verify Posting Shipment is not allowed on Transfer Order with Item Tracking Lines and partial Ship Qty.
        Initialize();

        // [GIVEN] Create Lot-tracked item
        CreateTrackedItem(Item, false, true, false, true);

        // [GIVEN] Create two Locations
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationWhite);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationBlue);

        // [GIVEN] The item is in inventory on location "W".
        LotNo := CreateLotNoInformation(Item."No.");
        LotNo2 := CreateLotNoInformation(Item."No.");
        PostItemJournalWithTracking(Item."No.", LocationWhite.Code, LotNo, LotNo2, 100);

        // [GIVEN] Transfer Order from "W" to "B" with Item Tracking Lines
        CreateTransferOrderWithItemTracking(TransferHeader, Item."No.", LocationWhite.Code, LocationBlue.Code, LotNo, LotNo2, 20);

        // [WHEN] Update Qty. to Ship on Transfer Line
        UpdateQtyToShipOnTransferLine(TransferHeader, 5);

        // [THEN] Post the Transfer Shipment
        asserterror LibraryInventory.PostTransferHeader(TransferHeader, true, false);
    end;

    [Test]
    [HandlerFunctions('LotItemTrackingLinesPageHandler')]
    procedure VerifyQtyToHandleOnReceiptTrackingLinesForPartialPostingTransferOrder()
    var
        Item: Record Item;
        LocationWhite: Record Location;
        LocationBlue: Record Location;
        TransferHeader: Record "Transfer Header";
        LotNo, LotNo2 : Code[20];
    begin
        // [SCENARIO 468270] Verify Qty. to Handle on receipt tracking lines for partial posting transfer order
        Initialize();

        // [GIVEN] Create Lot-tracked item
        CreateTrackedItem(Item, false, true, false, true);

        // [GIVEN] Create two Locations
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationWhite);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationBlue);

        // [GIVEN] The item is in inventory on location "W".
        LotNo := CreateLotNoInformation(Item."No.");
        LotNo2 := CreateLotNoInformation(Item."No.");
        PostItemJournalWithTracking(Item."No.", LocationWhite.Code, LotNo, LotNo2, 10, 10);

        // [GIVEN] Transfer Order from "W" to "B" with Item Tracking Lines
        CreateTransferOrderWithItemTracking(TransferHeader, Item."No.", LocationWhite.Code, LocationBlue.Code, LotNo, LotNo2, 10, 3);

        // [GIVEN] Update Qty. to Ship on Transfer Line
        UpdateQtyToShipOnTransferLine(TransferHeader, 5);

        // [WHEN] Post the Transfer Shipment
        LibraryInventory.PostTransferHeader(TransferHeader, true, false);
        LibraryInventory.PostTransferHeader(TransferHeader, true, false);

        // [THEN] Verify results
        VerifyQtyOnReservationEntriesForLotNo(TransferHeader, Item."No.", LocationBlue.Code, LotNo, 5);
        VerifyQtyOnReservationEntriesForLotNo(TransferHeader, Item."No.", LocationBlue.Code, LotNo2, 5);
    end;

    [Test]
    procedure TransferHeaderReservationFromStock()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ReservationFromStock: Enum "Reservation From Stock";
    begin
        // [SCENARIO 563164] Reserved from Stock has "Full" status on Statistics page of Transfer Order when there is non-inventory Item is in the Transfer Lines.
        Initialize();

        // [GIVEN] Create Transfer Header and Transfer Line.
        CreateTransferOrderQtyOneReservedOutbound(TransferHeader, TransferLine);

        // [THEN]
        Assert.AreEqual(
            ReservationFromStock::Full,
            TransferHeader.GetQtyReservedFromStockState(),
            StrSubstNo(
                ReservationFromStockErr,
                ReservationFromStock::Full,
                TransferHeader.TableCaption()));
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Transfer Reservation");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Transfer Reservation");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();

        isInitialized := true;

        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Transfer Reservation");
    end;

    local procedure CreateSOAsDemandAndPOAsSupplyAtDifferentLocations(var SalesLine: Record "Sales Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary; SNSpecific: Boolean; LNSpecific: Boolean): Code[20]
    var
        Item: Record Item;
        FromLocation: Record Location;
        ToLocation: Record Location;
        TransitLocation: Record Location;
        StockkeepingUnit: Record "Stockkeeping Unit";
        Qty: Integer;
    begin
        CreateTrackedItem(Item, SNSpecific, LNSpecific, false, false);
        CreateLocationsChain(FromLocation, ToLocation, TransitLocation);
        CreateItemSKUForLocation(
          Item."No.", FromLocation.Code, StockkeepingUnit."Reordering Policy"::Order,
          StockkeepingUnit."Replenishment System"::"Prod. Order", '');
        CreateItemSKUForLocation(
          Item."No.", ToLocation.Code, StockkeepingUnit."Reordering Policy"::Order,
          StockkeepingUnit."Replenishment System"::Transfer, FromLocation.Code);
        Qty := CreateSourceTempTrackingSpecification(TempTrackingSpecification, SNSpecific, LNSpecific);
        CreateSalesOrderLine(SalesLine, ToLocation.Code, Item."No.", Qty);

        Item.SetRecFilter();
        CalcRegPlanAndCarryOut(Item, SalesLine."Shipment Date");
        exit(FindAndReleaseProductionOrderByItemNo(Item."No."));
    end;

    local procedure CreateReserveAlwaysItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate(Reserve, Item.Reserve::Always);
        Item.Modify(true);
    end;

    local procedure CreateTrackedItem(var Item: Record Item; SNSpecific: Boolean; LNSpecific: Boolean; SNWhseTracking: Boolean; LNWhseTracking: Boolean)
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, SNSpecific, LNSpecific);
        ItemTrackingCode.Validate("SN Warehouse Tracking", SNWhseTracking);
        ItemTrackingCode.Validate("Lot Warehouse Tracking", LNWhseTracking);
        ItemTrackingCode.Modify(true);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Modify(true);
    end;

    local procedure CreateLotTrackedItemForPlanning(var Item: Record Item)
    begin
        LibraryItemTracking.CreateLotItem(Item);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::Order);
        Item.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        Item.Modify(true);
    end;

    local procedure CreateItemSKUForLocation(ItemNo: Code[20]; LocationCode: Code[10]; ReorderingPolicy: Enum "Reordering Policy"; ReplenishmentSystem: Enum "Replenishment System"; TransferFromCode: Code[10])
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, LocationCode, ItemNo, '');
        StockkeepingUnit.Validate("Reordering Policy", ReorderingPolicy);
        StockkeepingUnit.Validate("Replenishment System", ReplenishmentSystem);
        StockkeepingUnit.Validate("Transfer-from Code", TransferFromCode);
        StockkeepingUnit.Modify(true);
    end;

    local procedure CreateLocationsChain(var FromLocation: Record Location; var ToLocation: Record Location; var TransitLocation: Record Location)
    var
        TransferRoute: Record "Transfer Route";
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(FromLocation);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(ToLocation);
        LibraryWarehouse.CreateInTransitLocation(TransitLocation);
        LibraryInventory.CreateTransferRoute(TransferRoute, FromLocation.Code, ToLocation.Code);
        TransferRoute.Validate("In-Transit Code", TransitLocation.Code);
        TransferRoute.Modify(true);
    end;

    local procedure CreateLocationSetUpForInvtPickPutaway(var Location: Record Location)
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateLocationWMS(Location, true, true, true, false, false);
        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 3, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
    end;

    local procedure CreateItemInventory(Item: Record Item; Location: Record Location)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseOrder(PurchaseHeader, Location.Code, Item."No.", 1);
        PostPurchaseDocument(PurchaseHeader);
    end;

    local procedure PostPurchaseDocument(PurchaseHeader: Record "Purchase Header")
    begin
        // Update Vendor Invoice No on Purchase Header.
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesOrderLine(var SalesLine: Record "Sales Line"; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesOrder(SalesHeader, SalesLine, LocationCode, ItemNo, Quantity);
    end;

    local procedure CreateReserveAlwaysItemSupplyAndLocationsChain(var PurchaseLine: Record "Purchase Line"; var Item: Record Item; var FromLocation: Record Location; var ToLocation: Record Location; var TransitLocation: Record Location)
    begin
        CreateReserveAlwaysItemAndLocationsChain(Item, FromLocation, ToLocation, TransitLocation);
        CreateSupply(PurchaseLine, Item, FromLocation);
    end;

    local procedure CreateReserveAlwaysItemWithInventoryAndLocationsChain(var Item: Record Item; var FromLocation: Record Location; var ToLocation: Record Location; var TransitLocation: Record Location)
    begin
        CreateReserveAlwaysItemAndLocationsChain(Item, FromLocation, ToLocation, TransitLocation);
        CreateItemInventory(Item, FromLocation);
    end;

    local procedure CreateReserveAlwaysItemAndLocationsChain(var Item: Record Item; var FromLocation: Record Location; var ToLocation: Record Location; var TransitLocation: Record Location)
    begin
        CreateReserveAlwaysItem(Item);
        CreateLocationsChain(FromLocation, ToLocation, TransitLocation);
    end;

    local procedure CreateSupplyFromTransferLineQtyOneReservedOutbound(var TransferLine: Record "Transfer Line")
    var
        Item: Record Item;
        FromLocation: Record Location;
        ToLocation: Record Location;
        TransitLocation: Record Location;
    begin
        CreateReserveAlwaysItemWithInventoryAndLocationsChain(Item, FromLocation, ToLocation, TransitLocation);
        CreateTransferLineQtyOne(TransferLine, Item."No.", FromLocation.Code, ToLocation.Code, TransitLocation.Code, WorkDate());
        AutoReserveTransferLine(TransferLine, TransferLine."Shipment Date", "Transfer Direction"::Outbound);
    end;

    local procedure CreateTransferLineQtyOne(var TransferLine: Record "Transfer Line"; ItemNo: Code[20]; FromLocationCode: Code[10]; ToLocationCode: Code[10]; TransitLocationCode: Code[10]; ReceiptDate: Date)
    var
        TransferHeader: Record "Transfer Header";
    begin
        CreateTransferOrderQtyOne(TransferHeader, TransferLine, ItemNo, FromLocationCode, ToLocationCode, TransitLocationCode, ReceiptDate);
    end;

    local procedure CreateTransferOrderQtyOne(var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line"; ItemNo: Code[20]; FromLocationCode: Code[10]; ToLocationCode: Code[10]; TransitLocationCode: Code[10]; ReceiptDate: Date)
    begin
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocationCode, ToLocationCode, TransitLocationCode);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, 1);
        TransferLine.Validate("Receipt Date", ReceiptDate);
        TransferLine.Modify(true);
    end;

    local procedure CreateTransferOrder(var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line"; ItemNo: Code[20]; Qty: Decimal)
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationInTransit: Record Location;
    begin
        CreateLocationsChain(LocationFrom, LocationTo, LocationInTransit);
        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationInTransit.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Qty);
    end;

    local procedure CreateAndReleaseTransferOrder(var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line"; FromLocationCode: Code[10]; ToLocationCode: Code[10]; ItemNo: Code[20]; Qty: Decimal)
    var
        InTransitLocation: Record Location;
    begin
        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);
        CreateTransferLineQtyOne(
          TransferLine, ItemNo, FromLocationCode, ToLocationCode, InTransitLocation.Code, LibraryRandom.RandDate(5));
        TransferLine.Validate("Shipment Date", WorkDate());
        TransferLine.Validate(Quantity, Qty);
        TransferLine.Modify(true);
        TransferHeader.Get(TransferLine."Document No.");
        LibraryInventory.ReleaseTransferOrder(TransferHeader);
    end;

    local procedure CreateAndReleaseTransferOrderWithItemTracking(var TransferHeader: Record "Transfer Header"; ItemNo: Code[20]; FromLocationCode: Code[10]; ToLocationCode: Code[10])
    var
        InTransitLocation: Record Location;
        TransferLine: Record "Transfer Line";
    begin
        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);
        CreateTransferOrderQtyOne(
          TransferHeader, TransferLine, ItemNo, FromLocationCode, ToLocationCode, InTransitLocation.Code, WorkDate());
        LibraryVariableStorage.Enqueue(ItemTrackingOption::SelectEntries);
        TransferLine.OpenItemTrackingLines("Transfer Direction"::Outbound);
        LibraryInventory.ReleaseTransferOrder(TransferHeader);
    end;

    local procedure CreateDemandFromSalesOrderLineQtyOne(var SalesLine: Record "Sales Line"; ItemNo: Code[20]; LocationCode: Code[10]; ShipmentDate: Date)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, 1);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Validate("Shipment Date", ShipmentDate);
        SalesLine.Modify(true);
    end;

    local procedure CreateDemandFromTransferLineQtyOne(var TransferLine: Record "Transfer Line"; ItemNo: Code[20]; LocationCode: Code[10]; ShipmentDate: Date)
    var
        ToLocation: Record Location;
        TransitLocation: Record Location;
    begin
        LibraryWarehouse.CreateLocation(ToLocation);
        LibraryWarehouse.CreateInTransitLocation(TransitLocation);
        CreateTransferLineQtyOne(TransferLine, ItemNo, LocationCode, ToLocation.Code, TransitLocation.Code, WorkDate());
        TransferLine.Validate("Shipment Date", ShipmentDate);
        TransferLine.Modify(true);
    end;

    local procedure CreateDemandFromServiceLineQtyOne(var ServiceLine: Record "Service Line"; ItemNo: Code[20]; LocationCode: Code[10]; NeededByDate: Date)
    var
        ServiceHeader: Record "Service Header";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, '');
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNo);
        ServiceLine.Validate(Quantity, 1);
        ServiceLine.Validate("Location Code", LocationCode);
        ServiceLine.Validate("Needed by Date", NeededByDate);
        ServiceLine.Modify(true);
    end;

    local procedure CreateDemandFromJobPlanningLineQtyOne(var JobPlanningLine: Record "Job Planning Line"; ItemNo: Code[20]; LocationCode: Code[10]; PlanDate: Date)
    var
        Job: Record Job;
        JobTaskLine: Record "Job Task";
    begin
        LibraryJob.CreateJob(Job);
        Job.Validate("Apply Usage Link", true);
        Job.Modify();

        // Job Task Line:
        LibraryJob.CreateJobTask(Job, JobTaskLine);
        JobTaskLine.Modify();

        // Job Planning Line:
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Budget,
          JobPlanningLine.Type::Item, JobTaskLine, JobPlanningLine);

        JobPlanningLine.Validate("Planning Date", PlanDate);
        JobPlanningLine.Validate("Usage Link", true);

        JobPlanningLine.Validate("No.", ItemNo);
        JobPlanningLine.Validate("Location Code", LocationCode);
        JobPlanningLine.Validate(Quantity, 1);
        JobPlanningLine.Modify();
    end;

    local procedure CreateSKUWithPlanningParameters(var SKU: Record "Stockkeeping Unit"; ItemNo: Code[20]; LocationCode: Code[10]; ReplenishmentSystem: Enum "Replenishment System"; TransferFromCode: Code[10]; ReorderingPolicy: Enum "Reordering Policy")
    begin
        Clear(SKU);
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(SKU, LocationCode, ItemNo, '');
        SKU.Validate("Replenishment System", ReplenishmentSystem);
        SKU.Validate("Transfer-from Code", TransferFromCode);

        if SKU."Replenishment System" = SKU."Replenishment System"::Purchase then
            SKU.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());

        SKU.Validate("Reordering Policy", ReorderingPolicy);
        SKU.Modify(true);
    end;

    local procedure AutoReserveTransferLine(var TransferLine: Record "Transfer Line"; AvailabilityDate: Date; Direction: Enum "Transfer Direction")
    var
        ReservationManagement: Codeunit "Reservation Management";
        FullAutoReservation: Boolean;
    begin
        ReservationManagement.SetReservSource(TransferLine, Direction);
        ReservationManagement.AutoReserve(FullAutoReservation, TransferLine.Description, AvailabilityDate, TransferLine.Quantity, TransferLine."Quantity (Base)");
    end;

    local procedure AutoReserveSalesLine(var SalesLine: Record "Sales Line"; AvailabilityDate: Date)
    var
        ReservationManagement: Codeunit "Reservation Management";
        FullAutoReservation: Boolean;
    begin
        ReservationManagement.SetReservSource(SalesLine);
        ReservationManagement.AutoReserve(FullAutoReservation, SalesLine.Description, AvailabilityDate, SalesLine.Quantity, SalesLine."Quantity (Base)");
    end;

    local procedure AutoReservePurchaseLine(var PurchaseLine: Record "Purchase Line"; AvailabilityDate: Date)
    var
        ReservationManagement: Codeunit "Reservation Management";
        FullAutoReservation: Boolean;
    begin
        ReservationManagement.SetReservSource(PurchaseLine);
        ReservationManagement.AutoReserve(FullAutoReservation, PurchaseLine.Description, AvailabilityDate, PurchaseLine.Quantity, PurchaseLine."Quantity (Base)");
    end;

    local procedure AutoReserveTransferLineInbound(var TransferLine: Record "Transfer Line"; AvailabilityDate: Date)
    begin
        AutoReserveTransferLine(TransferLine, AvailabilityDate, "Transfer Direction"::Inbound);
    end;

    local procedure FindTransferInboundReservationEntry(var ReservationEntry: Record "Reservation Entry"; ItemNo: Code[20]; SourceID: Code[20])
    begin
        ReservationEntry.SetRange(Positive, true);
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Reservation);
        ReservationEntry.SetRange("Source Subtype", Direction::Inbound);
        ReservationEntry.SetRange("Source ID", SourceID);
        ReservationEntry.FindFirst();
    end;

    local procedure CreateTransferOrderQtyOneReservedOutbound(var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line")
    var
        Item: Record Item;
        FromLocation: Record Location;
        ToLocation: Record Location;
        TransitLocation: Record Location;
    begin
        CreateReserveAlwaysItemWithInventoryAndLocationsChain(Item, FromLocation, ToLocation, TransitLocation);
        CreateTransferOrderQtyOne(
          TransferHeader, TransferLine, Item."No.", FromLocation.Code, ToLocation.Code, TransitLocation.Code, WorkDate());
        AutoReserveTransferLine(TransferLine, TransferLine."Shipment Date", "Transfer Direction"::Outbound);
    end;

    local procedure CreateTransferLineQtyOneReservedOutbound(var TransferLine: Record "Transfer Line")
    var
        Item: Record Item;
        FromLocation: Record Location;
        ToLocation: Record Location;
        TransitLocation: Record Location;
        TransferHeader: Record "Transfer Header";
    begin
        CreateReserveAlwaysItemWithInventoryAndLocationsChain(Item, FromLocation, ToLocation, TransitLocation);
        CreateTransferOrderQtyOne(
          TransferHeader, TransferLine, Item."No.", FromLocation.Code, ToLocation.Code, TransitLocation.Code, WorkDate());
        AutoReserveTransferLine(TransferLine, TransferLine."Shipment Date", "Transfer Direction"::Outbound);
    end;

    local procedure CreateReservedDemandQtyOne(ItemNo: Code[20]; LocationCode: Code[10]; ShipmentDate: Date)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, 1);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Validate("Shipment Date", ShipmentDate);
        SalesLine.Modify(true);
        AutoReserveSalesLine(SalesLine, ShipmentDate);
    end;

    local procedure CreateUnreservedDemandQtyOne(ItemNo: Code[20]; LocationCode: Code[10]; ShipmentDate: Date)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, 1);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Validate("Shipment Date", ShipmentDate);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesOrderReservedFromInboundTransfer(var SalesLine: Record "Sales Line"; var TransferLine: Record "Transfer Line"; Qty: Decimal)
    begin
        CreateDemandFromSalesOrderLineQtyOne(
          SalesLine, TransferLine."Item No.", TransferLine."Transfer-to Code", LibraryRandom.RandDateFromInRange(WorkDate(), 6, 10));
        SalesLine.Validate(Quantity, Qty);
        SalesLine.Modify(true);
        AutoReserveTransferLineInbound(TransferLine, SalesLine."Shipment Date");
    end;

    local procedure CreateShippingAgentServiceCodeWith1YShippingTime(var ShippingAgentCode: Code[10]; var ShippingAgentServiceCode: Code[10])
    var
        ShippingAgent: Record "Shipping Agent";
        ShippingAgentServices: Record "Shipping Agent Services";
        ShippingTime: DateFormula;
    begin
        Evaluate(ShippingTime, '<+1Y>');
        LibraryInventory.CreateShippingAgent(ShippingAgent);
        LibraryInventory.CreateShippingAgentService(ShippingAgentServices, ShippingAgent.Code, ShippingTime);
        ShippingAgentCode := ShippingAgentServices."Shipping Agent Code";
        ShippingAgentServiceCode := ShippingAgentServices.Code;
    end;

    local procedure CreateSupply(var PurchaseLine: Record "Purchase Line"; Item: Record Item; FromLocation: Record Location)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);
        PurchaseLine.Validate("Location Code", FromLocation.Code);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSupplyAndDemandFromTransferLine(var PurchaseLine: Record "Purchase Line"; var TransferLine: Record "Transfer Line"; ShipmentDate: Date)
    var
        Item: Record Item;
        FromLocation: Record Location;
        ToLocation: Record Location;
        TransitLocation: Record Location;
        TransferHeader: Record "Transfer Header";
    begin
        CreateReserveAlwaysItemSupplyAndLocationsChain(PurchaseLine, Item, FromLocation, ToLocation, TransitLocation);
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocation.Code, ToLocation.Code, TransitLocation.Code);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 1);
        TransferLine.Validate("Shipment Date", ShipmentDate);
        TransferLine.Modify(true);
    end;

    local procedure CreateSupplyAndDemandFromTransferOrder(var PurchaseLine: Record "Purchase Line"; var TransferHeader: Record "Transfer Header"; ShipmentDate: Date)
    var
        Item: Record Item;
        FromLocation: Record Location;
        ToLocation: Record Location;
        TransitLocation: Record Location;
        TransferLine: Record "Transfer Line";
    begin
        CreateReserveAlwaysItemSupplyAndLocationsChain(PurchaseLine, Item, FromLocation, ToLocation, TransitLocation);
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocation.Code, ToLocation.Code, TransitLocation.Code);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 1);
        TransferHeader.Validate("Shipment Date", ShipmentDate);
        TransferHeader.Modify(true);
    end;

    local procedure CreateSourceTempTrackingSpecification(var TempTrackingSpecification: Record "Tracking Specification" temporary; SNSpecific: Boolean; LNSpecific: Boolean) TotQty: Integer
    var
        QtyInLine: Integer;
        QtyOfLines: Integer;
        i: Integer;
    begin
        QtyOfLines := LibraryRandom.RandIntInRange(5, 10);
        for i := 1 to QtyOfLines do begin
            TempTrackingSpecification.Init();
            if SNSpecific then begin
                QtyInLine := 1;
                TempTrackingSpecification."Serial No." := LibraryUtility.GenerateRandomCode(
                    TempTrackingSpecification.FieldNo("Serial No."), DATABASE::"Tracking Specification");
            end else
                QtyInLine := LibraryRandom.RandInt(10);
            if LNSpecific then
                TempTrackingSpecification."Lot No." := LibraryUtility.GenerateRandomCode(
                    TempTrackingSpecification.FieldNo("Lot No."), DATABASE::"Tracking Specification");
            TempTrackingSpecification."Quantity (Base)" := QtyInLine;
            TotQty += QtyInLine;
            TempTrackingSpecification."Entry No." := i;
            TempTrackingSpecification.Insert();
        end;
    end;

    local procedure CreateOutputJournalWithTrackingSpecification(var ItemJournalLine: Record "Item Journal Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary; ItemNo: Code[20]; ProdOrderNo: Code[20])
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ReservationEntry: Record "Reservation Entry";
    begin
        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate);
        ItemJournalTemplate.Validate(Type, ItemJournalTemplate.Type::Output);
        ItemJournalTemplate.Modify(true);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        TempTrackingSpecification.FindSet();
        repeat
            LibraryInventory.CreateItemJournalLine(
              ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, ItemJournalLine."Entry Type"::Output, '', 0);
            ItemJournalLine.Validate("Order Type", ItemJournalLine."Order Type"::Production);
            ItemJournalLine.Validate("Order No.", ProdOrderNo);
            ItemJournalLine.Validate("Item No.", ItemNo);
            ItemJournalLine.Validate("Output Quantity", TempTrackingSpecification."Quantity (Base)");
            ItemJournalLine.Modify(true);
            LibraryItemTracking.CreateItemJournalLineItemTracking(
              ReservationEntry, ItemJournalLine,
              TempTrackingSpecification."Serial No.", TempTrackingSpecification."Lot No.", TempTrackingSpecification."Quantity (Base)");
        until TempTrackingSpecification.Next() = 0;
    end;

    local procedure CreateAndPostOutputJournalWithTrackingSpecification(var TempTrackingSpecification: Record "Tracking Specification" temporary; ItemNo: Code[20]; ProdOrderNo: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateOutputJournalWithTrackingSpecification(ItemJournalLine, TempTrackingSpecification, ItemNo, ProdOrderNo);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateAndPostInventoryPickFromOutboundTransfer(var WarehouseActivityLine: Record "Warehouse Activity Line"; TransferOrderNo: Code[20]; QtyToHandle: Decimal; LotNo: Code[50])
    var
        WarehouseRequest: Record "Warehouse Request";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseRequest."Source Document"::"Outbound Transfer", TransferOrderNo, false, true, false);
        FindWarehouseActivityLine(WarehouseActivityLine, WarehouseActivityLine."Activity Type"::"Invt. Pick", TransferOrderNo);
        WarehouseActivityLine.Validate("Qty. to Handle", QtyToHandle);
        WarehouseActivityLine.Validate("Lot No.", LotNo);
        WarehouseActivityLine.Modify(true);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);
    end;

    local procedure CreateAndPostInventoryPutawayFromInboundTransfer(var WarehouseActivityLine: Record "Warehouse Activity Line"; TransferOrderNo: Code[20]; LocationCode: Code[10]; QtyToHandle: Decimal; LotNo: Code[50])
    var
        Bin: Record Bin;
        WarehouseRequest: Record "Warehouse Request";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseRequest."Source Document"::"Inbound Transfer", TransferOrderNo, true, false, false);
        FindWarehouseActivityLine(WarehouseActivityLine, WarehouseActivityLine."Activity Type"::"Invt. Put-away", TransferOrderNo);
        LibraryWarehouse.FindBin(Bin, LocationCode, '', 1);
        WarehouseActivityLine.Validate("Bin Code", Bin.Code);
        WarehouseActivityLine.Validate("Qty. to Handle", QtyToHandle);
        WarehouseActivityLine.Validate("Lot No.", LotNo);
        WarehouseActivityLine.Modify(true);
        WarehouseActivityHeader.Get(WarehouseActivityHeader.Type::"Invt. Put-away", WarehouseActivityLine."No.");
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);
    end;

    local procedure CalcRegPlanAndCarryOut(var Item: Record Item; ToDate: Date)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        LibraryPlanning.CalcRegenPlanForPlanWkshPlanningParams(Item, WorkDate(), ToDate, true);
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", Item."No.");
        RequisitionLine.ModifyAll("Accept Action Message", true);
        RequisitionLine.FindFirst();
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);
    end;

    local procedure FindAndReleaseProductionOrderByItemNo(ItemNo: Code[20]): Code[20]
    var
        ProductionOrder: Record "Production Order";
    begin
        FindProductionOrderByItemNo(ProductionOrder, ItemNo);
        LibraryManufacturing.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Released, WorkDate(), false);
        FindProductionOrderByItemNo(ProductionOrder, ItemNo);
        exit(ProductionOrder."No.");
    end;

    local procedure FindProductionOrderByItemNo(var ProductionOrder: Record "Production Order"; ItemNo: Code[20])
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange("Item No.", ItemNo);
        ProdOrderLine.FindFirst();
        ProductionOrder.SetRange(Status, ProdOrderLine.Status);
        ProductionOrder.SetRange("No.", ProdOrderLine."Prod. Order No.");
        ProductionOrder.FindFirst();
    end;

    local procedure FindPurchaseLine(var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20])
    begin
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", ItemNo);
        PurchaseLine.FindFirst();
    end;

    local procedure FindTransferLine(var TransferLine: Record "Transfer Line"; ItemNo: Code[20])
    begin
        TransferLine.SetRange("Item No.", ItemNo);
        TransferLine.FindFirst();
    end;

    local procedure FindWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; ActivityType: Enum "Warehouse Activity Type"; SourceNo: Code[20])
    begin
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.FindFirst();
    end;

    local procedure FindSetWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; ActivityType: Enum "Warehouse Activity Type"; SourceNo: Code[20])
    begin
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.FindSet();
    end;

    local procedure MockPurchaseLine(var PurchaseLine: Record "Purchase Line"; PlannedReceiptDate: Date; ItemNo: Code[20])
    begin
        PurchaseLine."Document Type" := PurchaseLine."Document Type"::Order;
        PurchaseLine."Document No." := LibraryUtility.GenerateGUID();
        PurchaseLine."Planned Receipt Date" := PlannedReceiptDate;
        PurchaseLine.Type := PurchaseLine.Type::Item;
        PurchaseLine."No." := ItemNo;
        PurchaseLine.Insert();
    end;

    local procedure MockSalesLine(var SalesLine: Record "Sales Line"; ShipmentDate: Date; ItemNo: Code[20])
    begin
        SalesLine."Document Type" := SalesLine."Document Type"::Order;
        SalesLine."Document No." := LibraryUtility.GenerateGUID();
        SalesLine."Shipment Date" := ShipmentDate;
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine."No." := ItemNo;
        SalesLine.Insert();
    end;

    local procedure MockTransferLine(var TransferLine: Record "Transfer Line"; ItemNo: Code[20]; ShipmentDate: Date; ReceiptDate: Date)
    begin
        TransferLine."Document No." := LibraryUtility.GenerateGUID();
        TransferLine."Line No." := LibraryUtility.GetNewRecNo(TransferLine, TransferLine.FieldNo("Line No."));
        TransferLine."Shipment Date" := ShipmentDate;
        TransferLine."Receipt Date" := ReceiptDate;
        TransferLine."Item No." := ItemNo;
        TransferLine.Insert();
    end;

    local procedure MockReservationEntry(var ReservationEntry: Record "Reservation Entry"; ItemNo: Code[20]; IsPositive: Boolean; SourceType: Integer; SourceSubtype: Option; SourceID: Code[20]; SourceRefNo: Integer; Qty: Decimal; ReservationStatus: Enum "Reservation Status"; ShipmentDate: Date)
    begin
        ReservationEntry."Item No." := ItemNo;
        ReservationEntry.Positive := IsPositive;
        ReservationEntry."Source Type" := SourceType;
        ReservationEntry."Source Subtype" := SourceSubtype;
        ReservationEntry."Source ID" := SourceID;
        ReservationEntry."Source Ref. No." := SourceRefNo;
        ReservationEntry.Quantity := Qty;
        ReservationEntry."Reservation Status" := ReservationStatus;
        ReservationEntry."Shipment Date" := ShipmentDate;
        ReservationEntry.Insert();
    end;

    local procedure UpdateTrackedInventory(LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; LotNo: Code[50]; Qty: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, LocationCode, BinCode, Qty);
        LibraryVariableStorage.Enqueue(ItemTrackingOption::AssignLotNo);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(Qty);
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure UpdateTrackedInventoryOnWMSLocation(LocationCode: Code[10]; ItemNo: Code[20]; LotNo: Code[50]; Qty: Decimal)
    var
        Bin: Record Bin;
    begin
        LibraryWarehouse.FindBin(Bin, LocationCode, '', 1);
        UpdateTrackedInventory(LocationCode, Bin.Code, ItemNo, LotNo, Qty);
    end;

    local procedure UpdateTrackedInventoryOnFullWMSLocation(LocationCode: Code[10]; ItemNo: Code[20]; Qty: Decimal)
    begin
        LibraryVariableStorage.Enqueue(LibraryUtility.GenerateGUID());
        LibraryVariableStorage.Enqueue(Qty);
        LibraryWarehouse.UpdateInventoryOnLocationWithDirectedPutAwayAndPick(ItemNo, LocationCode, Qty, true);
    end;

    local procedure UpdateQtyToHandleOnWarehouseActivityLines(var WarehouseActivityLine: Record "Warehouse Activity Line"; QtyToHandle: Decimal)
    begin
        WarehouseActivityLine.FindSet();
        repeat
            WarehouseActivityLine.Validate("Qty. to Handle", QtyToHandle);
            WarehouseActivityLine.Modify(true);
        until WarehouseActivityLine.Next() = 0;
    end;

    local procedure UpdateQtyToShipAndBaseOnTransferLine(var TransferLine: Record "Transfer Line"; Qty: Decimal; QtyBase: Decimal)
    begin
        TransferLine.Find();
        TransferLine."Qty. to Ship" := Qty;
        TransferLine."Qty. to Ship (Base)" := QtyBase;
        TransferLine.Modify();
    end;

    local procedure VerifyTrackingSpecification(var TempTrackingSpecification: Record "Tracking Specification" temporary; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceBatchName: Code[20]; SourceProdOrderLine: Integer; SourceRefNo: Integer; SignFactor: Integer)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Source Type", SourceType);
        ReservationEntry.SetRange("Source Subtype", SourceSubtype);
        ReservationEntry.SetRange("Source ID", SourceID);
        ReservationEntry.SetRange("Source Batch Name", SourceBatchName);
        ReservationEntry.SetRange("Source Prod. Order Line", SourceProdOrderLine);
        ReservationEntry.SetRange("Source Ref. No.", SourceRefNo);
        TempTrackingSpecification.FindSet();
        repeat
            ReservationEntry.SetRange("Serial No.", TempTrackingSpecification."Serial No.");
            ReservationEntry.SetRange("Lot No.", TempTrackingSpecification."Lot No.");
            ReservationEntry.FindFirst();
            ReservationEntry.TestField("Quantity (Base)", TempTrackingSpecification."Quantity (Base)" * SignFactor);
        until TempTrackingSpecification.Next() = 0;
    end;

    local procedure UpdateQtyToShipOnTransferLine(var TransferHeader: Record "Transfer Header"; QtyToShip: Decimal)
    var
        TransferLine: Record "Transfer Line";
    begin
        TransferLine.SetRange("Document No.", TransferHeader."No.");
        TransferLine.FindFirst();
        TransferLine.Validate("Qty. to Ship", QtyToShip);
        TransferLine.Modify(true);
    end;

    local procedure CreateTransferOrderWithItemTracking(var TransferHeader: Record "Transfer Header"; ItemNo: Code[20]; FromLocationCode: Code[10]; ToLocationCode: Code[10]; TrackingNo: Code[20]; TrackingNo2: Code[20]; QtyToHandle: Decimal)
    var
        InTransitLocation: Record Location;
        TransferLine: Record "Transfer Line";
    begin
        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);
        CreateTransferOrder(
          TransferHeader, TransferLine, ItemNo, FromLocationCode, ToLocationCode, InTransitLocation.Code, WorkDate(), QtyToHandle);
        LibraryVariableStorage.Enqueue(TrackingNo);
        LibraryVariableStorage.Enqueue(QtyToHandle / 2);
        LibraryVariableStorage.Enqueue(TrackingNo2);
        LibraryVariableStorage.Enqueue(QtyToHandle / 2);
        TransferLine.OpenItemTrackingLines("Transfer Direction"::Outbound);
    end;

    local procedure CreateTransferOrderWithItemTracking(var TransferHeader: Record "Transfer Header"; ItemNo: Code[20]; FromLocationCode: Code[10]; ToLocationCode: Code[10]; TrackingNo: Code[20]; TrackingNo2: Code[20]; QtyToBase: Decimal; QtyToHandle: Decimal)
    var
        InTransitLocation: Record Location;
        TransferLine: Record "Transfer Line";
    begin
        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);
        CreateTransferOrder(
          TransferHeader, TransferLine, ItemNo, FromLocationCode, ToLocationCode, InTransitLocation.Code, WorkDate(), QtyToBase);
        LibraryVariableStorage.Enqueue(TrackingNo);
        LibraryVariableStorage.Enqueue(QtyTobase / 2);
        LibraryVariableStorage.Enqueue(QtyToHandle);
        LibraryVariableStorage.Enqueue(TrackingNo2);
        LibraryVariableStorage.Enqueue(QtyTobase / 2);
        LibraryVariableStorage.Enqueue(QtyToBase / 2 - QtyToHandle);
        TransferLine.OpenItemTrackingLines("Transfer Direction"::Outbound);
    end;

    local procedure CreateTransferOrder(var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line"; ItemNo: Code[20]; FromLocationCode: Code[10]; ToLocationCode: Code[10]; TransitLocationCode: Code[10]; ReceiptDate: Date; Qty: Decimal)
    begin
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocationCode, ToLocationCode, TransitLocationCode);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Qty);
        TransferLine.Validate("Receipt Date", ReceiptDate);
        TransferLine.Modify(true);
    end;

    local procedure CreateLotNoInformation(ItemNo: Code[20]): Code[20]
    var
        LotNoInformation: Record "Lot No. Information";
    begin
        LibraryInventory.CreateLotNoInformation(
          LotNoInformation, ItemNo, '',
          LibraryUtility.GenerateRandomCode(LotNoInformation.FieldNo("Lot No."), DATABASE::"Lot No. Information"));
        exit(LotNoInformation."Lot No.");
    end;

    local procedure PostItemJournalWithTracking(ItemNo: Code[20]; LocationCode: Code[10]; TrackingNo: Code[20]; TrackingNo2: Code[20]; QtyToHandle: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJournalLine(ItemJournalLine, ItemNo, LocationCode, '', QtyToHandle);
        LibraryVariableStorage.Enqueue(TrackingNo);
        LibraryVariableStorage.Enqueue(QtyToHandle / 2);
        LibraryVariableStorage.Enqueue(TrackingNo2);
        LibraryVariableStorage.Enqueue(QtyToHandle / 2);
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure PostItemJournalWithTracking(ItemNo: Code[20]; LocationCode: Code[10]; TrackingNo: Code[20]; TrackingNo2: Code[20]; QtyToBase: Decimal; QtyToHandle: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJournalLine(ItemJournalLine, ItemNo, LocationCode, '', QtyToBase + QtyToHandle);
        LibraryVariableStorage.Enqueue(TrackingNo);
        LibraryVariableStorage.Enqueue(QtyToBase);
        LibraryVariableStorage.Enqueue(QtyToHandle);
        LibraryVariableStorage.Enqueue(TrackingNo2);
        LibraryVariableStorage.Enqueue(QtyToBase);
        LibraryVariableStorage.Enqueue(QtyToHandle);
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Quantity: Decimal)
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        SelectAndClearItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::Item);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Modify(true);
    end;

    local procedure SelectAndClearItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; TemplateType: Enum "Item Journal Template Type")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, TemplateType);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, TemplateType, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
    end;

    local procedure VerifyQtyOnReservationEntriesForLotNo(var TransferHeader: Record "Transfer Header"; ItemNo: Code[20]; LocationCode: Code[10]; LotNo: Code[20]; Quantity: Decimal)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetSourceFilter(Database::"Transfer Line", 1, TransferHeader."No.", -1, true);
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.SetRange("Location Code", LocationCode);
        ReservationEntry.SetRange("Lot No.", LotNo);
        ReservationEntry.CalcSums("Quantity (Base)", "Qty. to Handle (Base)", "Qty. to Invoice (Base)");
        Assert.AreEqual(Quantity, ReservationEntry."Quantity (Base)", ReservEntryQtyIncorrectErr);
        Assert.AreEqual(Quantity, ReservationEntry."Qty. to Handle (Base)", ReservEntryQtyIncorrectErr);
        Assert.AreEqual(Quantity, ReservationEntry."Qty. to Invoice (Base)", ReservEntryQtyIncorrectErr);
    end;

    local procedure RunDummyConfirm()
    begin
        if Confirm(DummyQst) then;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhseItemTrackingLinesPageHandler(var WhseItemTrackingLines: TestPage "Whse. Item Tracking Lines")
    begin
        WhseItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
        WhseItemTrackingLines.Quantity.SetValue(LibraryVariableStorage.DequeueDecimal());
        WhseItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        case LibraryVariableStorage.DequeueInteger() of
            ItemTrackingOption::AssignLotNo:
                begin
                    ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
                    ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
                end;
            ItemTrackingOption::SelectEntries:
                begin
                    ItemTrackingLines."Select Entries".Invoke();
                    ItemTrackingLines.First();
                    ItemTrackingLines."Qty. to Handle (Base)".SetValue(0);
                end;
            ItemTrackingOption::ChangeLotQty:
                begin
                    ItemTrackingLines.FILTER.SetFilter("Lot No.", LibraryVariableStorage.DequeueText());
                    ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
                end;
            ItemTrackingOption::AssignSerialNos:
                ItemTrackingLines."Assign Serial No.".Invoke();
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ItemTrackingLinesLotPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        QtyToHandle: Decimal;
    begin
        ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
        QtyToHandle := LibraryVariableStorage.DequeueDecimal();
        ItemTrackingLines."Quantity (Base)".SetValue(QtyToHandle);
        ItemTrackingLines.Next();
        ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
        QtyToHandle := LibraryVariableStorage.DequeueDecimal();
        ItemTrackingLines."Quantity (Base)".SetValue(QtyToHandle);
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure LotItemTrackingLinesPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        QtyToBase, QtyToHandle : Decimal;
    begin
        ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
        QtyToBase := LibraryVariableStorage.DequeueDecimal();
        QtyToHandle := LibraryVariableStorage.DequeueDecimal();
        ItemTrackingLines."Quantity (Base)".SetValue(QtyToBase);
        ItemTrackingLines."Qty. to Handle (Base)".SetValue(QtyToHandle);
        ItemTrackingLines.Next();
        ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
        QtyToBase := LibraryVariableStorage.DequeueDecimal();
        QtyToHandle := LibraryVariableStorage.DequeueDecimal();
        ItemTrackingLines."Quantity (Base)".SetValue(QtyToBase);
        ItemTrackingLines."Qty. to Handle (Base)".SetValue(QtyToHandle);
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSummaryPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EnterQuantityToCreateModalPageHandler(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantityToCreate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchaseReceiptsModalPageHandler(var PostedPurchaseReceipts: TestPage "Posted Purchase Receipts")
    begin
        PostedPurchaseReceipts.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchaseReceiptLinesModalPageHandler(var PostedPurchaseReceiptLines: TestPage "Posted Purchase Receipt Lines")
    begin
        PostedPurchaseReceiptLines.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure CounterOfConfirmsHandler(Question: Text; var Reply: Boolean)
    begin
        CounterOfConfirms += 1;
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmCloseWithQtyZero(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}

