// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Test;

using Microsoft.Assembly.Document;
using Microsoft.Sales.Document;
using Microsoft.Purchases.Document;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Item;

codeunit 137925 "SCM Assembly Reservation II"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Assembly] [Reservation] [SCM]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Assembly Reservation II");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Assembly Reservation II");

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Assembly Reservation II");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAsmHdrCalcFieldsReservQty()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyHeader2: Record "Assembly Header";
        ReservEntry: Record "Reservation Entry";
        Qty: Decimal;
        QtyBase: Decimal;
        Qty2: Decimal;
        QtyBase2: Decimal;
    begin
        Initialize();

        MockAsmOrderHeader(AssemblyHeader, IDcode20('asm'), '', '', '', 0D, 0, 0, 1);
        Qty := 500;
        QtyBase := 100;
        Qty2 := 50;
        QtyBase2 := 10;

        MockReservEntry(
          ReservEntry, DATABASE::"Assembly Header",
          AssemblyHeader."No.", AssemblyHeader."Document Type".AsInteger(), 0, QtyBase, Qty);
        MockReservEntry(
          ReservEntry, DATABASE::"Assembly Header",
          AssemblyHeader."No.", AssemblyHeader."Document Type".AsInteger(), 0, QtyBase2, Qty2);

        // Insert entries that are not from Assembly Order to test filters
        // Another Assembly Order
        MockReservEntry(
          ReservEntry, DATABASE::"Assembly Header", IDcode20('any'), AssemblyHeader."Document Type".AsInteger(), 0, 11, 33);
        // Assembly Line Table
        MockReservEntry(
          ReservEntry, DATABASE::"Assembly Line", AssemblyHeader."No.", AssemblyHeader."Document Type".AsInteger(), 0, 12, 44);
        // Assembly Qoute
        AssemblyHeader2."Document Type" := AssemblyHeader2."Document Type"::Quote;
        MockReservEntry(
          ReservEntry, DATABASE::"Assembly Header", AssemblyHeader."No.", AssemblyHeader2."Document Type".AsInteger(), 0, 5, 22);

        // Test calculated fields
        AssemblyHeader.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        VerifyCalculatedFields(Qty + Qty2, AssemblyHeader."Reserved Quantity", QtyBase + QtyBase2, AssemblyHeader."Reserved Qty. (Base)");

        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSummEntryNoAsmOrder()
    var
        AssemblyHeader: Record "Assembly Header";
        ReservEntry: Record "Reservation Entry";
    begin
        Initialize();

        // Test procedure SummEntryNo on TAB337
        AssemblyHeader."Document Type" := AssemblyHeader."Document Type"::Order;

        MockReservEntry(ReservEntry, DATABASE::"Assembly Header", 'ANY', AssemblyHeader."Document Type".AsInteger(), 0, 0, 0);

        // Offset for Assembly Header is 141 and subtype (as integer) is added
        Assert.AreEqual(142, ReservEntry.SummEntryNo(), 'Assembly Header has the wrong offset in Reservation');

        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateReservEntryForAsmHdr()
    var
        AssemblyHeader: Record "Assembly Header";
        SalesLine: Record "Sales Line";
        ReservEntry: Record "Reservation Entry";
        AsmHeaderReserve: Codeunit "Assembly Header-Reserve";
        ReservEntryFoundByLinkToSource: Boolean;
    begin
        Initialize();

        // Test Procedure CreateReservation, CreateReservationSetFrom and DeleteLine in codeunit 925 Assembly Header-Reserve
        CreateAsmHdrResFromSalesLine(AssemblyHeader, SalesLine);

        // Verification
        ReservEntryFoundByLinkToSource :=
          FindLastRerservationByLink(
            DATABASE::"Assembly Header", AssemblyHeader."Document Type".AsInteger(), AssemblyHeader."No.", 0, ReservEntry);
        Assert.IsTrue(ReservEntryFoundByLinkToSource, 'Reservation Entry NOT created for Assembly Order'); // Verifies link

        VerifyReservationEntryFields(
          ReservEntry, true,
          AssemblyHeader."Item No.", AssemblyHeader."Variant Code", AssemblyHeader."Location Code",
          AssemblyHeader."Due Date",
          AssemblyHeader."Quantity (Base)", AssemblyHeader."Remaining Quantity", AssemblyHeader."Qty. per Unit of Measure");

        AssemblyHeader.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        VerifyCalculatedFields(
          AssemblyHeader.Quantity, AssemblyHeader."Reserved Quantity",
          AssemblyHeader."Quantity (Base)", AssemblyHeader."Reserved Qty. (Base)");

        // Verification - Delete Line
        AsmHeaderReserve.DeleteLine(AssemblyHeader);

        ReservEntryFoundByLinkToSource :=
          FindLastRerservationByLink(
            DATABASE::"Assembly Header", AssemblyHeader."Document Type".AsInteger(), AssemblyHeader."No.", 0, ReservEntry);
        Assert.IsFalse(ReservEntryFoundByLinkToSource, 'Reservation Entry NOT deleted for Assembly Order');

        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateReservEntryNotEnough()
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        SalesLine: Record "Sales Line";
        TrackingSpecification: Record "Tracking Specification";
        AsmHeaderReserve: Codeunit "Assembly Header-Reserve";
        AvailabilityDate: Date;
        QtyToReserve: Decimal;
        AvailableToReserve: Decimal;
        LocationCode: Code[10];
        VariantCode: Code[10];
    begin
        Initialize();

        // Test Procedure CreateReservation and CreateReservationSetFrom in codeunit 925 Assembly Header-Reserve
        // when not enough available to reserve for
        MockItem(Item);
        LocationCode := IDcode10('l');
        VariantCode := IDcode10('v');

        AvailabilityDate := Today;
        QtyToReserve := 23;
        AvailableToReserve := 10;

        // Line to Reserv from
        MockSalesOrderLine(SalesLine, Item."No.", LocationCode, VariantCode, AvailabilityDate, QtyToReserve, QtyToReserve, 1, 10000);

        // Line to Reserv for
        MockAsmOrderHeader(
          AssemblyHeader, IDcode20('asm'), Item."No.", LocationCode, VariantCode, AvailabilityDate, AvailableToReserve, AvailableToReserve, 1);

        // Create Reservation Entry
        TrackingSpecification.InitTrackingSpecification(
          DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", '', 0, SalesLine."Line No.",
          SalesLine."Variant Code", SalesLine."Location Code", SalesLine."Qty. per Unit of Measure");
        AsmHeaderReserve.CreateReservationSetFrom(TrackingSpecification);
        asserterror AsmHeaderReserve.CreateReservation(AssemblyHeader, 'Test', AvailabilityDate, 0, QtyToReserve);

        // Verification
        Assert.AreEqual(GetLastErrorText, StrSubstNo('Reserved quantity cannot be greater than %1.', AvailableToReserve), '');

        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateReservEntryForSOL()
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        SalesLine: Record "Sales Line";
        ReservEntry: Record "Reservation Entry";
        ReservEntry2: Record "Reservation Entry";
        TrackingSpecification: Record "Tracking Specification";
        SalesLineReserve: Codeunit "Sales Line-Reserve";
        AvailabilityDate: Date;
        QtyToReserve: Decimal;
        ReservEntryFoundByLinkToSource: Boolean;
        LocationCode: Code[10];
        VariantCode: Code[10];
    begin
        Initialize();

        // Show how to use procedures in codeunit 99000832 Sales Line-Reserve to create reservations between
        // Assembly Header and Sales Order Lines (SOL) - Assemble to Order
        // This test will also verify Order Binding

        // Sales order line
        MockItem(Item);
        LocationCode := IDcode10('l');
        VariantCode := IDcode10('v');

        AvailabilityDate := Today;
        QtyToReserve := 23;

        // Line to Reserv from
        MockAsmOrderHeader(
          AssemblyHeader, IDcode20('asm'), Item."No.", LocationCode, VariantCode, AvailabilityDate, QtyToReserve, QtyToReserve, 1);

        // Line to Reserv for
        MockSalesOrderLine(SalesLine, Item."No.", LocationCode, VariantCode, AvailabilityDate, QtyToReserve, QtyToReserve, 1, 10000);

        // Create Reservation Entry
        SalesLineReserve.SetBinding(ReservEntry2.Binding::"Order-to-Order");
        TrackingSpecification.InitTrackingSpecification(
          DATABASE::"Assembly Header", AssemblyHeader."Document Type".AsInteger(), AssemblyHeader."No.", '', 0, 0,
          AssemblyHeader."Variant Code", AssemblyHeader."Location Code", AssemblyHeader."Qty. per Unit of Measure");
        SalesLineReserve.CreateReservationSetFrom(TrackingSpecification);
        SalesLineReserve.CreateBindingReservation(SalesLine, AssemblyHeader.Description, AssemblyHeader."Due Date", 0, QtyToReserve);

        // Verification
        ReservEntryFoundByLinkToSource :=
          FindLastRerservationByLink(
            DATABASE::"Assembly Header", AssemblyHeader."Document Type".AsInteger(), AssemblyHeader."No.", 0, ReservEntry);
        Assert.IsTrue(ReservEntryFoundByLinkToSource, 'Reservation Entry NOT created for Assembly Order'); // Verifies link
        Assert.AreEqual(ReservEntry2.Binding::"Order-to-Order", ReservEntry.Binding, 'Order binding is not set');

        VerifyReservationEntryFields(
          ReservEntry, true,
          AssemblyHeader."Item No.", AssemblyHeader."Variant Code", AssemblyHeader."Location Code",
          AssemblyHeader."Due Date",
          AssemblyHeader."Quantity (Base)", AssemblyHeader."Remaining Quantity", AssemblyHeader."Qty. per Unit of Measure");

        AssemblyHeader.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        VerifyCalculatedFields(
          AssemblyHeader.Quantity, AssemblyHeader."Reserved Quantity",
          AssemblyHeader."Quantity (Base)", AssemblyHeader."Reserved Qty. (Base)");

        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAutoReservOneLineAsmHdr()
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        SalesLine: Record "Sales Line";
        ReservEntry: Record "Reservation Entry";
        ReservMgt: Codeunit "Reservation Management";
        AvailabilityDate: Date;
        QtyToReserve: Decimal;
        QtyToReserve2: Decimal;
        RemainingQtyToReserve: Decimal;
        ReservEntryFoundByLinkToSource: Boolean;
        LocationCode: Code[10];
        VariantCode: Code[10];
        ReservSummEntryNo: Integer;
    begin
        Initialize();

        MockItem(Item);
        LocationCode := IDcode10('l');
        VariantCode := IDcode10('v');

        AvailabilityDate := Today;
        QtyToReserve := 10;
        ReservSummEntryNo := 32; // Sales Order Line - Reserv From

        // Line to Reserv from
        MockSalesOrderLine(SalesLine, Item."No.", LocationCode, VariantCode, AvailabilityDate, QtyToReserve, QtyToReserve, 1, 10000);

        // Line to Reserv for
        MockAsmOrderHeader(
          AssemblyHeader, IDcode20('asm'), Item."No.", LocationCode, VariantCode, AvailabilityDate, QtyToReserve, QtyToReserve, 1);

        // Auto Reserve
        ReservMgt.SetReservSource(AssemblyHeader);
        RemainingQtyToReserve := QtyToReserve;
        ReservMgt.AutoReserveOneLine(ReservSummEntryNo, QtyToReserve2, RemainingQtyToReserve, 'Test', AvailabilityDate);

        // Verify
        ReservEntryFoundByLinkToSource :=
          FindLastRerservationByLink(
            DATABASE::"Assembly Header", AssemblyHeader."Document Type".AsInteger(), AssemblyHeader."No.", 0, ReservEntry);
        Assert.IsTrue(ReservEntryFoundByLinkToSource, 'Reservation Entry NOT created for Assembly Order');

        AssemblyHeader.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        VerifyCalculatedFields(
          AssemblyHeader.Quantity, AssemblyHeader."Reserved Quantity",
          AssemblyHeader."Quantity (Base)", AssemblyHeader."Reserved Qty. (Base)");

        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAutoReservFullAsmHdr()
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        SalesLine: Record "Sales Line";
        ReservEntry: Record "Reservation Entry";
        ReservMgt: Codeunit "Reservation Management";
        FullAutoReservation: Boolean;
        AvailabilityDate: Date;
        QtyToReserve: Decimal;
        RemainingQtyToReserve: Decimal;
        ReservEntryFoundByLinkToSource: Boolean;
        LocationCode: Code[10];
        VariantCode: Code[10];
    begin
        Initialize();

        MockItem(Item);
        LocationCode := IDcode10('l');
        VariantCode := IDcode10('v');

        AvailabilityDate := Today;
        QtyToReserve := 10;

        // Line to Reserv from
        MockSalesOrderLine(SalesLine, Item."No.", LocationCode, VariantCode, AvailabilityDate, QtyToReserve, QtyToReserve, 1, 10000);

        // Line to Reserv for
        MockAsmOrderHeader(
          AssemblyHeader, IDcode20('asm'), Item."No.", LocationCode, VariantCode, AvailabilityDate, QtyToReserve, QtyToReserve, 1);

        // Auto Reserve
        ReservMgt.SetReservSource(AssemblyHeader);
        RemainingQtyToReserve := QtyToReserve;
        ReservMgt.AutoReserve(FullAutoReservation, 'Test', AvailabilityDate, 0, RemainingQtyToReserve);

        // Verify
        ReservEntryFoundByLinkToSource :=
          FindLastRerservationByLink(
            DATABASE::"Assembly Header", AssemblyHeader."Document Type".AsInteger(), AssemblyHeader."No.", 0, ReservEntry);
        Assert.IsTrue(ReservEntryFoundByLinkToSource, 'Reservation Entry NOT created for Assembly Order');

        VerifyReservationEntryFields(
          ReservEntry, true,
          AssemblyHeader."Item No.", AssemblyHeader."Variant Code", AssemblyHeader."Location Code",
          AssemblyHeader."Due Date",
          AssemblyHeader."Quantity (Base)", AssemblyHeader."Remaining Quantity", AssemblyHeader."Qty. per Unit of Measure");

        AssemblyHeader.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        VerifyCalculatedFields(
          AssemblyHeader.Quantity, AssemblyHeader."Reserved Quantity",
          AssemblyHeader."Quantity (Base)", AssemblyHeader."Reserved Qty. (Base)");

        Assert.IsTrue(FullAutoReservation, 'The quantity is NOT fully reserved');

        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAutoReservFullLoopSOLines()
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        SalesLine: Record "Sales Line";
        ReservEntry: Record "Reservation Entry";
        ReservMgt: Codeunit "Reservation Management";
        FullAutoReservation: Boolean;
        AvailabilityDate: Date;
        QtyToReserve: Decimal;
        RemainingQtyToReserve: Decimal;
        AvailableQtyNotEnough: Decimal;
        ReservEntryFoundByLinkToSource: Boolean;
        LocationCode: Code[10];
        VariantCode: Code[10];
    begin
        Initialize();

        // Loop more lines to make Reservation
        MockItem(Item);
        LocationCode := IDcode10('l');
        VariantCode := IDcode10('v');

        AvailabilityDate := Today;
        QtyToReserve := 10;
        AvailableQtyNotEnough := 4;

        // Line to Reserv from
        MockSalesOrderLine(
          SalesLine, Item."No.", LocationCode, VariantCode, AvailabilityDate,
          AvailableQtyNotEnough, AvailableQtyNotEnough, 1, 10000);
        MockSalesOrderLine(
          SalesLine, Item."No.", LocationCode, VariantCode, AvailabilityDate,
          QtyToReserve - AvailableQtyNotEnough, QtyToReserve - AvailableQtyNotEnough, 1, 20000);

        // Line to Reserv for
        MockAsmOrderHeader(
          AssemblyHeader, IDcode20('asm'), Item."No.", LocationCode, VariantCode, AvailabilityDate, QtyToReserve, QtyToReserve, 1);

        // Auto Reserve
        ReservMgt.SetReservSource(AssemblyHeader);
        RemainingQtyToReserve := QtyToReserve;
        ReservMgt.AutoReserve(FullAutoReservation, 'Test', AvailabilityDate, 0, RemainingQtyToReserve);

        // Verify
        ReservEntryFoundByLinkToSource :=
          FindLastRerservationByLink(
            DATABASE::"Assembly Header", AssemblyHeader."Document Type".AsInteger(), AssemblyHeader."No.", 0, ReservEntry);
        Assert.IsTrue(ReservEntryFoundByLinkToSource, 'Reservation Entry NOT created for Assembly Order');

        AssemblyHeader.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        VerifyCalculatedFields(
          AssemblyHeader.Quantity, AssemblyHeader."Reserved Quantity",
          AssemblyHeader."Quantity (Base)", AssemblyHeader."Reserved Qty. (Base)");

        Assert.IsTrue(FullAutoReservation, 'The quantity is NOT fully reserved');

        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAutoReservNotFullAsmHdr()
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        SalesLine: Record "Sales Line";
        ReservEntry: Record "Reservation Entry";
        ReservMgt: Codeunit "Reservation Management";
        FullAutoReservation: Boolean;
        AvailabilityDate: Date;
        QtyToReserve: Decimal;
        RemainingQtyToReserve: Decimal;
        AvailableToReserve: Decimal;
        ReservEntryFoundByLinkToSource: Boolean;
        LocationCode: Code[10];
        VariantCode: Code[10];
    begin
        Initialize();

        MockItem(Item);
        LocationCode := IDcode10('l');
        VariantCode := IDcode10('v');

        AvailabilityDate := Today;
        QtyToReserve := 10;
        AvailableToReserve := 6;

        // Line to Reserv from
        MockSalesOrderLine(SalesLine, Item."No.", LocationCode, VariantCode, AvailabilityDate, AvailableToReserve, AvailableToReserve, 1, 10000);

        // Line to Reserv for
        MockAsmOrderHeader(
          AssemblyHeader, IDcode20('asm'), Item."No.", LocationCode, VariantCode, AvailabilityDate, QtyToReserve, QtyToReserve, 1);

        // Auto Reserve
        ReservMgt.SetReservSource(AssemblyHeader);
        RemainingQtyToReserve := QtyToReserve;
        ReservMgt.AutoReserve(FullAutoReservation, 'Test', AvailabilityDate, 0, RemainingQtyToReserve);

        // Verify
        ReservEntryFoundByLinkToSource :=
          FindLastRerservationByLink(
            DATABASE::"Assembly Header", AssemblyHeader."Document Type".AsInteger(), AssemblyHeader."No.", 0, ReservEntry);
        Assert.IsTrue(ReservEntryFoundByLinkToSource, 'Reservation Entry NOT created for Assembly Order');

        VerifyReservationEntryFields(
          ReservEntry, true,
          AssemblyHeader."Item No.", AssemblyHeader."Variant Code", AssemblyHeader."Location Code",
          AssemblyHeader."Due Date",
          AvailableToReserve, AvailableToReserve, AssemblyHeader."Qty. per Unit of Measure");

        AssemblyHeader.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        VerifyCalculatedFields(
          AvailableToReserve, AssemblyHeader."Reserved Quantity",
          AvailableToReserve, AssemblyHeader."Reserved Qty. (Base)");

        Assert.IsFalse(FullAutoReservation, 'The quantity should NOT be fully reserved');

        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAutoReservNotFullWithAsmLi()
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        SalesLine: Record "Sales Line";
        ReservEntry: Record "Reservation Entry";
        ReservMgt: Codeunit "Reservation Management";
        FullAutoReservation: Boolean;
        AvailabilityDate: Date;
        QtyToReserve: Decimal;
        RemainingQtyToReserve: Decimal;
        AvailableToReserve: Decimal;
        ReservEntryFoundByLinkToSource: Boolean;
        LocationCode: Code[10];
        VariantCode: Code[10];
        AnotherLocationCode: Code[10];
    begin
        Initialize();

        // Verify that correct filters are set on Assembly Order Line
        MockItem(Item);
        LocationCode := IDcode10('l');
        AnotherLocationCode := IDcode10('l2');
        VariantCode := IDcode10('v');

        AvailabilityDate := Today;
        QtyToReserve := 10;
        AvailableToReserve := 6;

        // Line to Reserv from
        MockSalesOrderLine(SalesLine, Item."No.", LocationCode, VariantCode, AvailabilityDate, AvailableToReserve, AvailableToReserve, 1, 10000);

        // Line to Reserv for
        MockAsmOrderHeader(
          AssemblyHeader, IDcode20('asm'), Item."No.", LocationCode, VariantCode, AvailabilityDate, QtyToReserve, QtyToReserve, 1);

        // Line NOT to reserve from
        // Assembly Line with different Location, Variant etc. should not be considered in Auto Reservation
        MockAsmOrderLine(
          AssemblyLine, IDcode20('asml'), Item."No.", AnotherLocationCode, VariantCode, AvailabilityDate, QtyToReserve, QtyToReserve, 1, 10000);
        MockAsmOrderLine(
          AssemblyLine, IDcode20('asml'), Item."No.", '', '', AvailabilityDate, QtyToReserve, QtyToReserve, 1, 20000);

        // Auto Reserve
        ReservMgt.SetReservSource(AssemblyHeader);
        RemainingQtyToReserve := QtyToReserve;
        ReservMgt.AutoReserve(FullAutoReservation, 'Test', AvailabilityDate, 0, RemainingQtyToReserve);

        // Verify
        ReservEntryFoundByLinkToSource :=
          FindLastRerservationByLink(
            DATABASE::"Assembly Header", AssemblyHeader."Document Type".AsInteger(), AssemblyHeader."No.", 0, ReservEntry);
        Assert.IsTrue(ReservEntryFoundByLinkToSource, 'Reservation Entry NOT created for Assembly Order');

        VerifyReservationEntryFields(
          ReservEntry, true,
          AssemblyHeader."Item No.", AssemblyHeader."Variant Code", AssemblyHeader."Location Code",
          AssemblyHeader."Due Date",
          AvailableToReserve, AvailableToReserve, AssemblyHeader."Qty. per Unit of Measure");

        Assert.IsFalse(FullAutoReservation, 'The quantity should NOT be fully reserved');

        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAsmLineCalcFieldsReservQty()
    var
        AssemblyLine: Record "Assembly Line";
        AssemblyLine2: Record "Assembly Line";
        ReservEntry: Record "Reservation Entry";
        Qty: Decimal;
        QtyBase: Decimal;
        Qty2: Decimal;
        QtyBase2: Decimal;
    begin
        Initialize();

        MockAsmOrderLine(AssemblyLine, IDcode20('asml'), '', '', '', 0D, 0, 0, 1, 10000);
        Qty := -500;
        QtyBase := -100;
        Qty2 := -50;
        QtyBase2 := -10;

        MockReservEntry(
          ReservEntry, DATABASE::"Assembly Line",
          AssemblyLine."Document No.", AssemblyLine."Document Type".AsInteger(), AssemblyLine."Line No.",
          QtyBase, Qty);
        MockReservEntry(
          ReservEntry, DATABASE::"Assembly Line",
          AssemblyLine."Document No.", AssemblyLine."Document Type".AsInteger(), AssemblyLine."Line No.",
          QtyBase2, Qty2);

        // Insert entries that are not from Assembly Order to test filters
        // Another Assembly Line
        MockReservEntry(
          ReservEntry, DATABASE::"Assembly Line",
          AssemblyLine."Document No.", AssemblyLine."Document Type".AsInteger(), 20000, 3, 21);
        // Another Assembly Order
        MockReservEntry(
          ReservEntry, DATABASE::"Assembly Line",
          IDcode20('any'), AssemblyLine."Document Type".AsInteger(), AssemblyLine."Line No.", 4, 16);
        // Assembly Header Table
        MockReservEntry(
          ReservEntry, DATABASE::"Assembly Header",
          AssemblyLine."Document No.", AssemblyLine."Document Type".AsInteger(), AssemblyLine."Line No.", 12, 45);
        // Assembly Qoute
        AssemblyLine2."Document Type" := AssemblyLine2."Document Type"::Quote;
        MockReservEntry(
          ReservEntry, DATABASE::"Assembly Line",
          AssemblyLine."Document No.", AssemblyLine2."Document Type".AsInteger(), AssemblyLine."Line No.", 27, 77);

        // Test calculated fields
        AssemblyLine.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");

        VerifyCalculatedFields(-(Qty + Qty2), AssemblyLine."Reserved Quantity", -(QtyBase + QtyBase2), AssemblyLine."Reserved Qty. (Base)");

        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSummEntryNoAsmOrderLine()
    var
        AssemblyLine: Record "Assembly Line";
        ReservEntry: Record "Reservation Entry";
    begin
        Initialize();

        // Test procedure SummEntryNo on TAB337
        AssemblyLine."Document Type" := AssemblyLine."Document Type"::Order;

        MockReservEntry(ReservEntry, DATABASE::"Assembly Line", 'ANY', AssemblyLine."Document Type".AsInteger(), 0, 0, 0);

        // Offset for Assembly Line is 151 and subtype (as integer) is added
        Assert.AreEqual(152, ReservEntry.SummEntryNo(), 'Assembly Line has the wrong offset in Reservation');

        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateReservEntForAsmLine()
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        ReservEntry: Record "Reservation Entry";
        TrackingSpecification: Record "Tracking Specification";
        AssemblyLineReserve: Codeunit "Assembly Line-Reserve";
        AvailabilityDate: Date;
        QtyToReserve: Decimal;
        ReservEntryFoundByLinkToSource: Boolean;
        LocationCode: Code[10];
        VariantCode: Code[10];
    begin
        Initialize();

        // Test Procedure CreateReservation, CreateReservationSetFrom and DeleteLine in codeunit 926 Assembly Line-Reserve
        MockItem(Item);
        LocationCode := IDcode10('l');
        VariantCode := IDcode10('v');

        AvailabilityDate := Today;
        QtyToReserve := 23;

        // Line to Reserv from
        MockAsmOrderHeader(
          AssemblyHeader, IDcode20('asm'), Item."No.", LocationCode, VariantCode, AvailabilityDate, QtyToReserve, QtyToReserve, 1);

        // Line to Reserv for
        MockAsmOrderLine(
          AssemblyLine, IDcode20('asm'), Item."No.", LocationCode, VariantCode, AvailabilityDate, QtyToReserve, QtyToReserve, 1, 10000);

        // Create Reservation Entry
        TrackingSpecification.InitTrackingSpecification(
          DATABASE::"Assembly Header", AssemblyHeader."Document Type".AsInteger(), AssemblyHeader."No.", '', 0, 0,
          AssemblyHeader."Variant Code", AssemblyHeader."Location Code", AssemblyHeader."Qty. per Unit of Measure");
        AssemblyLineReserve.CreateReservationSetFrom(TrackingSpecification);
        AssemblyLineReserve.CreateBindingReservation(AssemblyLine, AssemblyHeader.Description, AssemblyHeader."Due Date", 0, QtyToReserve);

        // Verification
        ReservEntryFoundByLinkToSource :=
          FindLastRerservationByLink(
            DATABASE::"Assembly Line", AssemblyLine."Document Type".AsInteger(), AssemblyLine."Document No.", AssemblyLine."Line No.", ReservEntry);
        Assert.IsTrue(ReservEntryFoundByLinkToSource, 'Reservation Entry NOT created for Assembly Order Line'); // Verifies link

        VerifyReservationEntryFields(
          ReservEntry, false,
          AssemblyLine."No.", AssemblyLine."Variant Code", AssemblyLine."Location Code",
          AssemblyLine."Due Date",
          -AssemblyLine."Quantity (Base)", -AssemblyLine."Remaining Quantity", AssemblyLine."Qty. per Unit of Measure");

        AssemblyLine.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        VerifyCalculatedFields(
          AssemblyLine.Quantity, AssemblyLine."Reserved Quantity",
          AssemblyLine."Quantity (Base)", AssemblyLine."Reserved Qty. (Base)");

        // Verification - Delete Line
        AssemblyLineReserve.DeleteLine(AssemblyLine);

        ReservEntryFoundByLinkToSource :=
          FindLastRerservationByLink(
            DATABASE::"Assembly Line", AssemblyLine."Document Type".AsInteger(), AssemblyLine."Document No.", AssemblyLine."Line No.", ReservEntry);
        Assert.IsFalse(ReservEntryFoundByLinkToSource, 'Reservation Entry NOT deleted for Assembly Order');

        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAutoReservOneLineAsmLine()
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        ReservEntry: Record "Reservation Entry";
        ReservMgt: Codeunit "Reservation Management";
        AvailabilityDate: Date;
        QtyToReserve: Decimal;
        QtyToReserve2: Decimal;
        RemainingQtyToReserve: Decimal;
        ReservEntryFoundByLinkToSource: Boolean;
        LocationCode: Code[10];
        VariantCode: Code[10];
        ReservSummEntryNo: Integer;
    begin
        Initialize();

        MockItem(Item);
        LocationCode := IDcode10('l');
        VariantCode := IDcode10('v');

        AvailabilityDate := Today;
        QtyToReserve := 10;
        ReservSummEntryNo := 142; // Assembly Header - Reserv From

        // Line to Reserv from
        MockAsmOrderHeader(
          AssemblyHeader, IDcode20('asm'), Item."No.", LocationCode, VariantCode, AvailabilityDate, QtyToReserve, QtyToReserve, 1);

        // Line to Reserv for
        MockAsmOrderLine(
          AssemblyLine, IDcode20('asml'), Item."No.", LocationCode, VariantCode, AvailabilityDate, QtyToReserve, QtyToReserve, 1, 10000);

        // Auto Reserve
        ReservMgt.SetReservSource(AssemblyLine);
        RemainingQtyToReserve := QtyToReserve;
        QtyToReserve2 := Round(QtyToReserve / AssemblyLine."Qty. per Unit of Measure", 0.00001);
        ReservMgt.AutoReserveOneLine(ReservSummEntryNo, QtyToReserve2, RemainingQtyToReserve, 'Test', AvailabilityDate);

        // Verify
        ReservEntryFoundByLinkToSource :=
          FindLastRerservationByLink(
            DATABASE::"Assembly Line", AssemblyLine."Document Type".AsInteger(), AssemblyLine."Document No.", AssemblyLine."Line No.", ReservEntry);
        Assert.IsTrue(ReservEntryFoundByLinkToSource, 'Reservation Entry NOT created for Assembly Order');

        AssemblyLine.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        VerifyCalculatedFields(
          AssemblyLine.Quantity, AssemblyLine."Reserved Quantity",
          AssemblyLine."Quantity (Base)", AssemblyLine."Reserved Qty. (Base)");

        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAutoReservFullAsmLine()
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        ReservEntry: Record "Reservation Entry";
        ReservMgt: Codeunit "Reservation Management";
        FullAutoReservation: Boolean;
        AvailabilityDate: Date;
        QtyToReserve: Decimal;
        RemainingQtyToReserve: Decimal;
        ReservEntryFoundByLinkToSource: Boolean;
        LocationCode: Code[10];
        VariantCode: Code[10];
    begin
        Initialize();

        MockItem(Item);
        LocationCode := IDcode10('l');
        VariantCode := IDcode10('v');

        AvailabilityDate := Today;
        QtyToReserve := 10;

        // Line to Reserv from
        MockAsmOrderHeader(
          AssemblyHeader, IDcode20('asm'), Item."No.", LocationCode, VariantCode, AvailabilityDate, QtyToReserve, QtyToReserve, 1);

        // Line to Reserv for
        MockAsmOrderLine(
          AssemblyLine, IDcode20('asml'), Item."No.", LocationCode, VariantCode, AvailabilityDate, QtyToReserve, QtyToReserve, 1, 10000);

        // Auto Reserve
        ReservMgt.SetReservSource(AssemblyLine);
        RemainingQtyToReserve := QtyToReserve;
        ReservMgt.AutoReserve(FullAutoReservation, 'Test', AvailabilityDate, 0, RemainingQtyToReserve);

        // Verify
        ReservEntryFoundByLinkToSource :=
          FindLastRerservationByLink(
            DATABASE::"Assembly Line", AssemblyLine."Document Type".AsInteger(), AssemblyLine."Document No.", AssemblyLine."Line No.", ReservEntry);
        Assert.IsTrue(ReservEntryFoundByLinkToSource, 'Reservation Entry NOT created for Assembly Order');

        VerifyReservationEntryFields(
          ReservEntry, false,
          AssemblyLine."No.", AssemblyLine."Variant Code", AssemblyLine."Location Code",
          AssemblyLine."Due Date",
          -AssemblyLine."Quantity (Base)", -AssemblyLine."Remaining Quantity", AssemblyLine."Qty. per Unit of Measure");

        AssemblyLine.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        VerifyCalculatedFields(
          AssemblyLine.Quantity, AssemblyLine."Reserved Quantity",
          AssemblyLine."Quantity (Base)", AssemblyLine."Reserved Qty. (Base)");

        Assert.IsTrue(FullAutoReservation, 'The quantity is NOT fully reserved');

        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAutoReservFullAsmHeaders()
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        ReservEntry: Record "Reservation Entry";
        ReservMgt: Codeunit "Reservation Management";
        FullAutoReservation: Boolean;
        AvailabilityDate: Date;
        QtyToReserve: Decimal;
        RemainingQtyToReserve: Decimal;
        ReservEntryFoundByLinkToSource: Boolean;
        LocationCode: Code[10];
        VariantCode: Code[10];
        AvailableQtyNotEnough: Decimal;
    begin
        Initialize();

        MockItem(Item);
        LocationCode := IDcode10('l');
        VariantCode := IDcode10('v');

        AvailabilityDate := Today;
        QtyToReserve := 10;
        AvailableQtyNotEnough := 5;

        // Line to Reserv from
        MockAsmOrderHeader(
          AssemblyHeader, IDcode20('asm'), Item."No.",
          LocationCode, VariantCode, AvailabilityDate, AvailableQtyNotEnough, AvailableQtyNotEnough, 1);
        MockAsmOrderHeader(
          AssemblyHeader, IDcode20('asm2'), Item."No.",
          LocationCode, VariantCode, AvailabilityDate,
          QtyToReserve - AvailableQtyNotEnough, QtyToReserve - AvailableQtyNotEnough, 1);

        // Line to Reserv for
        MockAsmOrderLine(
          AssemblyLine, IDcode20('asml'), Item."No.", LocationCode, VariantCode, AvailabilityDate, QtyToReserve, QtyToReserve, 1, 10000);

        // Auto Reserve
        ReservMgt.SetReservSource(AssemblyLine);
        RemainingQtyToReserve := QtyToReserve;
        ReservMgt.AutoReserve(FullAutoReservation, 'Test', AvailabilityDate, 0, RemainingQtyToReserve);

        // Verify
        ReservEntryFoundByLinkToSource :=
          FindLastRerservationByLink(
            DATABASE::"Assembly Line", AssemblyLine."Document Type".AsInteger(), AssemblyLine."Document No.", AssemblyLine."Line No.", ReservEntry);
        Assert.IsTrue(ReservEntryFoundByLinkToSource, 'Reservation Entry NOT created for Assembly Order');

        AssemblyLine.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        VerifyCalculatedFields(
          AssemblyLine.Quantity, AssemblyLine."Reserved Quantity",
          AssemblyLine."Quantity (Base)", AssemblyLine."Reserved Qty. (Base)");

        Assert.IsTrue(FullAutoReservation, 'The quantity is NOT fully reserved');

        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAutoReservNotFullAsmLine()
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        ReservEntry: Record "Reservation Entry";
        ReservMgt: Codeunit "Reservation Management";
        FullAutoReservation: Boolean;
        AvailabilityDate: Date;
        QtyToReserve: Decimal;
        RemainingQtyToReserve: Decimal;
        AvailableToReserve: Decimal;
        ReservEntryFoundByLinkToSource: Boolean;
        LocationCode: Code[10];
        VariantCode: Code[10];
    begin
        Initialize();

        MockItem(Item);
        LocationCode := IDcode10('l');
        VariantCode := IDcode10('v');

        AvailabilityDate := Today;
        QtyToReserve := 10;
        AvailableToReserve := 6;

        // Line to Reserv from
        MockAsmOrderHeader(
          AssemblyHeader, IDcode20('asm'), Item."No.", LocationCode, VariantCode, AvailabilityDate, AvailableToReserve, AvailableToReserve, 1);

        // Line to Reserv for
        MockAsmOrderLine(
          AssemblyLine, IDcode20('asml'), Item."No.", LocationCode, VariantCode, AvailabilityDate, QtyToReserve, QtyToReserve, 1, 10000);

        // Auto Reserve
        ReservMgt.SetReservSource(AssemblyLine);
        RemainingQtyToReserve := QtyToReserve;
        ReservMgt.AutoReserve(FullAutoReservation, 'Test', AvailabilityDate, 0, RemainingQtyToReserve);

        // Verify
        ReservEntryFoundByLinkToSource :=
          FindLastRerservationByLink(
            DATABASE::"Assembly Line", AssemblyLine."Document Type".AsInteger(), AssemblyLine."Document No.", AssemblyLine."Line No.", ReservEntry);
        Assert.IsTrue(ReservEntryFoundByLinkToSource, 'Reservation Entry NOT created for Assembly Order');

        VerifyReservationEntryFields(
          ReservEntry, false,
          AssemblyLine."No.", AssemblyLine."Variant Code", AssemblyLine."Location Code",
          AssemblyLine."Due Date",
          -AvailableToReserve, -AvailableToReserve, AssemblyLine."Qty. per Unit of Measure");

        AssemblyLine.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        VerifyCalculatedFields(
          AvailableToReserve, AssemblyLine."Reserved Quantity",
          AvailableToReserve, AssemblyLine."Reserved Qty. (Base)");

        Assert.IsFalse(FullAutoReservation, 'The quantity should NOT be fully reserved');

        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAutoResNotFullWithAsmHdr()
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        ReservEntry: Record "Reservation Entry";
        ReservMgt: Codeunit "Reservation Management";
        FullAutoReservation: Boolean;
        AvailabilityDate: Date;
        QtyToReserve: Decimal;
        RemainingQtyToReserve: Decimal;
        AvailableToReserve: Decimal;
        ReservEntryFoundByLinkToSource: Boolean;
        LocationCode: Code[10];
        VariantCode: Code[10];
        AnotherLocationCode: Code[10];
    begin
        Initialize();

        // Verify that correct filters are set on Assembly Order
        MockItem(Item);
        LocationCode := IDcode10('l');
        AnotherLocationCode := IDcode10('l2');
        VariantCode := IDcode10('v');

        AvailabilityDate := Today;
        QtyToReserve := 10;
        AvailableToReserve := 6;

        // Line to Reserv from
        MockAsmOrderHeader(
          AssemblyHeader, IDcode20('asm'), Item."No.", LocationCode, VariantCode, AvailabilityDate, AvailableToReserve, AvailableToReserve, 1);

        // Line to Reserv for
        MockAsmOrderLine(
          AssemblyLine, IDcode20('asml'), Item."No.", LocationCode, VariantCode, AvailabilityDate, QtyToReserve, QtyToReserve, 1, 10000);

        // Line NOT to reserve from
        // Assembly Header with different Location, Variant etc. should not be considered in Auto Reservation
        MockAsmOrderHeader(
          AssemblyHeader, IDcode20('asm1'), Item."No.",
          AnotherLocationCode, VariantCode, AvailabilityDate, QtyToReserve, QtyToReserve, 1);
        MockAsmOrderHeader(
          AssemblyHeader, IDcode20('asm2'), Item."No.",
          '', '', AvailabilityDate,
          QtyToReserve, QtyToReserve, 1);

        // Auto Reserve
        ReservMgt.SetReservSource(AssemblyLine);
        RemainingQtyToReserve := QtyToReserve;
        ReservMgt.AutoReserve(FullAutoReservation, 'Test', AvailabilityDate, 0, RemainingQtyToReserve);

        // Verify Test
        ReservEntryFoundByLinkToSource :=
          FindLastRerservationByLink(
            DATABASE::"Assembly Line", AssemblyLine."Document Type".AsInteger(), AssemblyLine."Document No.", AssemblyLine."Line No.", ReservEntry);
        Assert.IsTrue(ReservEntryFoundByLinkToSource, 'Reservation Entry NOT created for Assembly Line');

        VerifyReservationEntryFields(
          ReservEntry, false,
          AssemblyLine."No.", AssemblyLine."Variant Code", AssemblyLine."Location Code",
          AssemblyLine."Due Date",
          -AvailableToReserve, -AvailableToReserve, AssemblyLine."Qty. per Unit of Measure");

        AssemblyLine.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        VerifyCalculatedFields(
          AvailableToReserve, AssemblyLine."Reserved Quantity",
          AvailableToReserve, AssemblyLine."Reserved Qty. (Base)");

        Assert.IsFalse(FullAutoReservation, 'The quantity should NOT be fully reserved');

        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDateConflictAsmHdr()
    var
        SalesLine: Record "Sales Line";
        AssemblyHeader: Record "Assembly Header";
        ReservEntry: Record "Reservation Entry";
        AsmReservCheckDateConfl: Codeunit "Asm. ReservCheckDateConfl";
        ReservEntryFoundByLinkToSource: Boolean;
        ErrorMessage: Text[250];
    begin
        Initialize();

        // Test Procedure AsssemblyHeaderCheck in codeunit 99000815 Reservation-Check Date Confl.
        CreateAsmHdrResFromSalesLine(AssemblyHeader, SalesLine);

        // Verify Test
        ReservEntryFoundByLinkToSource :=
          FindLastRerservationByLink(
            DATABASE::"Assembly Header", AssemblyHeader."Document Type".AsInteger(), AssemblyHeader."No.", 0, ReservEntry);
        Assert.IsTrue(ReservEntryFoundByLinkToSource, 'Reservation Entry NOT created for Assembly Line');

        // Due Date moved before Shipment Date in sales
        AssemblyHeader."Due Date" := CalcDate('<-10D>', SalesLine."Shipment Date");
        AsmReservCheckDateConfl.AssemblyHeaderCheck(AssemblyHeader, true);

        // Verify date is moved in Reservation Entry
        FindLastRerservationByLink(
          DATABASE::"Assembly Header", AssemblyHeader."Document Type".AsInteger(), AssemblyHeader."No.", 0, ReservEntry);
        Assert.AreEqual(
          AssemblyHeader."Due Date", ReservEntry."Expected Receipt Date",
          StrSubstNo('Reservation date should be moved to %1.', AssemblyHeader."Due Date"));

        // Date is moved after Shipment Date in sales
        AssemblyHeader."Due Date" := CalcDate('<10D>', SalesLine."Shipment Date");
        asserterror AsmReservCheckDateConfl.AssemblyHeaderCheck(AssemblyHeader, true);

        // Verifify error
        ErrorMessage := StrSubstNo('Reserved quantity (Base): %1, Date %2', AssemblyHeader."Quantity (Base)", AssemblyHeader."Due Date");
        Assert.IsTrue(Contains(GetLastErrorText, ErrorMessage), ErrorMessage);

        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVerifyQtyUpAsmHdr()
    var
        SalesLine: Record "Sales Line";
        AssemblyHeader: Record "Assembly Header";
        OldAssemblyHeader: Record "Assembly Header";
        NewAssemblyHeader: Record "Assembly Header";
        ReservEntry: Record "Reservation Entry";
        AssemblyHeaderReserve: Codeunit "Assembly Header-Reserve";
        ReservEntryFoundByLinkToSource: Boolean;
    begin
        Initialize();

        // Test Procedure VerifyQuantity in codeunit 925 Assembly Header-Reserve
        CreateAsmHdrResFromSalesLine(AssemblyHeader, SalesLine);

        // Verify Test
        ReservEntryFoundByLinkToSource :=
          FindLastRerservationByLink(
            DATABASE::"Assembly Header", AssemblyHeader."Document Type".AsInteger(), AssemblyHeader."No.", 0, ReservEntry);
        Assert.IsTrue(ReservEntryFoundByLinkToSource, 'Reservation Entry NOT created for Assembly Line');

        // Change quantity up
        OldAssemblyHeader := AssemblyHeader;
        NewAssemblyHeader := OldAssemblyHeader;
        NewAssemblyHeader.Quantity := NewAssemblyHeader.Quantity + 2;
        NewAssemblyHeader."Quantity (Base)" := NewAssemblyHeader.Quantity;
        NewAssemblyHeader."Remaining Quantity" := NewAssemblyHeader.Quantity;
        NewAssemblyHeader."Remaining Quantity (Base)" := NewAssemblyHeader.Quantity;
        AssemblyHeaderReserve.VerifyQuantity(NewAssemblyHeader, OldAssemblyHeader);

        // Verify quantity is NOT changed in Reservation Entry
        Clear(ReservEntry);
        ReservEntryFoundByLinkToSource :=
          FindLastRerservationByLink(
            DATABASE::"Assembly Header", AssemblyHeader."Document Type".AsInteger(), AssemblyHeader."No.", 0, ReservEntry);
        Assert.IsTrue(ReservEntryFoundByLinkToSource, 'Reservation Entry NOT created for Assembly Line');
        Assert.AreEqual(
          OldAssemblyHeader.Quantity, ReservEntry.Quantity,
          StrSubstNo('Reservation should not be changed'));

        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVerifyQtyDownAsmHdr()
    var
        SalesLine: Record "Sales Line";
        AssemblyHeader: Record "Assembly Header";
        OldAssemblyHeader: Record "Assembly Header";
        NewAssemblyHeader: Record "Assembly Header";
        ReservEntry: Record "Reservation Entry";
        AssemblyHeaderReserve: Codeunit "Assembly Header-Reserve";
        ReservEntryFoundByLinkToSource: Boolean;
    begin
        Initialize();

        // Test Procedure VerifyQuantity in codeunit 925 Assembly Header-Reserve
        CreateAsmHdrResFromSalesLine(AssemblyHeader, SalesLine);

        // Verify Test
        ReservEntryFoundByLinkToSource :=
          FindLastRerservationByLink(
            DATABASE::"Assembly Header", AssemblyHeader."Document Type".AsInteger(), AssemblyHeader."No.", 0, ReservEntry);
        Assert.IsTrue(ReservEntryFoundByLinkToSource, 'Reservation Entry NOT created for Assembly Line');

        // Change quantity down
        OldAssemblyHeader := AssemblyHeader;
        NewAssemblyHeader := OldAssemblyHeader;
        NewAssemblyHeader.Quantity := NewAssemblyHeader.Quantity - 1;
        NewAssemblyHeader."Quantity (Base)" := NewAssemblyHeader.Quantity;
        NewAssemblyHeader."Remaining Quantity" := NewAssemblyHeader.Quantity;
        NewAssemblyHeader."Remaining Quantity (Base)" := NewAssemblyHeader.Quantity;
        AssemblyHeaderReserve.VerifyQuantity(NewAssemblyHeader, OldAssemblyHeader);

        // Verify quantity is changed in Reservation Entry
        Clear(ReservEntry);
        ReservEntryFoundByLinkToSource :=
          FindLastRerservationByLink(
            DATABASE::"Assembly Header", AssemblyHeader."Document Type".AsInteger(), AssemblyHeader."No.", 0, ReservEntry);
        Assert.IsTrue(ReservEntryFoundByLinkToSource, 'Reservation Entry NOT created for Assembly Line');
        Assert.AreEqual(
          NewAssemblyHeader.Quantity, ReservEntry.Quantity,
          StrSubstNo('Reservation should be changed to %1.', NewAssemblyHeader.Quantity));

        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDateConflictAsmLine()
    var
        PurchLine: Record "Purchase Line";
        AssemblyLine: Record "Assembly Line";
        ReservEntry: Record "Reservation Entry";
        AsmReservCheckDateConfl: Codeunit "Asm. ReservCheckDateConfl";
        ReservEntryFoundByLinkToSource: Boolean;
        ErrorMessage: Text[250];
    begin
        Initialize();

        // Test Procedure AsssemblyLineCheck in codeunit 99000815 Reservation-Check Date Confl.
        CreateAsmLineResFromPurch(AssemblyLine, PurchLine);

        // Verify Test
        ReservEntryFoundByLinkToSource :=
          FindLastRerservationByLink(
            DATABASE::"Assembly Line", AssemblyLine."Document Type".AsInteger(), AssemblyLine."Document No.", AssemblyLine."Line No.", ReservEntry);
        Assert.IsTrue(ReservEntryFoundByLinkToSource, 'Reservation Entry NOT created for Assembly Line');

        // Date is moved after expected receipt date in purchase
        AssemblyLine."Due Date" := CalcDate('<10D>', PurchLine."Expected Receipt Date");
        AsmReservCheckDateConfl.AssemblyLineCheck(AssemblyLine, true);

        // Verify date is moved in Reservation Entry
        FindLastRerservationByLink(
          DATABASE::"Assembly Line", AssemblyLine."Document Type".AsInteger(), AssemblyLine."Document No.", AssemblyLine."Line No.", ReservEntry);
        Assert.AreEqual(
          AssemblyLine."Due Date", ReservEntry."Shipment Date",
          StrSubstNo('Reservation date should be moved to %1.', AssemblyLine."Due Date"));

        // Date is moved before expected receipt date in purchase
        AssemblyLine."Due Date" := CalcDate('<-10D>', PurchLine."Expected Receipt Date");
        asserterror AsmReservCheckDateConfl.AssemblyLineCheck(AssemblyLine, true);

        // Verify error
        ErrorMessage := StrSubstNo('Reserved quantity (Base): %1, Date %2', AssemblyLine."Quantity (Base)", AssemblyLine."Due Date");
        Assert.IsTrue(Contains(GetLastErrorText, ErrorMessage), ErrorMessage);

        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVerifyQtyUpAsmLine()
    var
        PurchLine: Record "Purchase Line";
        AssemblyLine: Record "Assembly Line";
        OldAssemblyLine: Record "Assembly Line";
        NewAssemblyLine: Record "Assembly Line";
        ReservEntry: Record "Reservation Entry";
        AssemblyLineReserve: Codeunit "Assembly Line-Reserve";
        ReservEntryFoundByLinkToSource: Boolean;
    begin
        Initialize();

        // Test Procedure VerifyQuantity in codeunit 926 Assembly Line-Reserve
        CreateAsmLineResFromPurch(AssemblyLine, PurchLine);

        // Verify Test
        ReservEntryFoundByLinkToSource :=
          FindLastRerservationByLink(
            DATABASE::"Assembly Line", AssemblyLine."Document Type".AsInteger(), AssemblyLine."Document No.", AssemblyLine."Line No.", ReservEntry);
        Assert.IsTrue(ReservEntryFoundByLinkToSource, 'Reservation Entry NOT created for Assembly Line');

        // Change quantity up
        OldAssemblyLine := AssemblyLine;
        NewAssemblyLine := OldAssemblyLine;
        NewAssemblyLine.Quantity := NewAssemblyLine.Quantity + 2;

        NewAssemblyLine.Quantity := NewAssemblyLine.Quantity - 1;
        NewAssemblyLine."Quantity (Base)" := NewAssemblyLine.Quantity;
        NewAssemblyLine."Remaining Quantity" := NewAssemblyLine.Quantity;
        NewAssemblyLine."Remaining Quantity (Base)" := NewAssemblyLine.Quantity;
        AssemblyLineReserve.VerifyQuantity(NewAssemblyLine, OldAssemblyLine);

        // Verify quantity is NOT changed in Reservation Entry
        Clear(ReservEntry);
        ReservEntryFoundByLinkToSource :=
          FindLastRerservationByLink(
            DATABASE::"Assembly Line", AssemblyLine."Document Type".AsInteger(), AssemblyLine."Document No.", AssemblyLine."Line No.", ReservEntry);
        Assert.IsTrue(ReservEntryFoundByLinkToSource, 'Reservation Entry NOT created for Assembly Line');
        Assert.AreEqual(
          -OldAssemblyLine.Quantity, ReservEntry.Quantity,
          StrSubstNo('Reservation should not be changed'));

        asserterror Error('') // roll back
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVerifyQtyDownAsmLine()
    var
        PurchLine: Record "Purchase Line";
        AssemblyLine: Record "Assembly Line";
        OldAssemblyLine: Record "Assembly Line";
        NewAssemblyLine: Record "Assembly Line";
        ReservEntry: Record "Reservation Entry";
        AssemblyLineReserve: Codeunit "Assembly Line-Reserve";
        ReservEntryFoundByLinkToSource: Boolean;
    begin
        Initialize();

        // Test Procedure VerifyQuantity in codeunit 926 Assembly Line-Reserve
        CreateAsmLineResFromPurch(AssemblyLine, PurchLine);

        // Verify Test
        ReservEntryFoundByLinkToSource :=
          FindLastRerservationByLink(
            DATABASE::"Assembly Line", AssemblyLine."Document Type".AsInteger(), AssemblyLine."Document No.", AssemblyLine."Line No.", ReservEntry);
        Assert.IsTrue(ReservEntryFoundByLinkToSource, 'Reservation Entry NOT created for Assembly Line');

        // Change quantity down
        OldAssemblyLine := AssemblyLine;
        NewAssemblyLine := OldAssemblyLine;
        NewAssemblyLine.Quantity := NewAssemblyLine.Quantity - 1;

        NewAssemblyLine.Quantity := NewAssemblyLine.Quantity - 1;
        NewAssemblyLine."Quantity (Base)" := NewAssemblyLine.Quantity;
        NewAssemblyLine."Remaining Quantity" := NewAssemblyLine.Quantity;
        NewAssemblyLine."Remaining Quantity (Base)" := NewAssemblyLine.Quantity;
        AssemblyLineReserve.VerifyQuantity(NewAssemblyLine, OldAssemblyLine);

        // Verify quantity is changed in Reservation Entry
        Clear(ReservEntry);
        ReservEntryFoundByLinkToSource :=
          FindLastRerservationByLink(
            DATABASE::"Assembly Line", AssemblyLine."Document Type".AsInteger(), AssemblyLine."Document No.", AssemblyLine."Line No.", ReservEntry);
        Assert.IsTrue(ReservEntryFoundByLinkToSource, 'Reservation Entry NOT created for Assembly Line');
        Assert.AreEqual(
          -NewAssemblyLine.Quantity, ReservEntry.Quantity,
          StrSubstNo('Reservation should be changed to %1.', -NewAssemblyLine.Quantity));

        asserterror Error('') // roll back
    end;

    local procedure VerifyReservationEntryFields(ReservEntry: Record "Reservation Entry"; Positive: Boolean; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; Date: Date; QtyBase: Decimal; Qty: Decimal; QtyPrUnit: Decimal)
    begin
        // Key
        Assert.AreEqual(Positive, ReservEntry.Positive, 'Wrong value in key field Positive');

        // Supply/Demand Fields
        Assert.AreEqual(ItemNo, ReservEntry."Item No.", 'Wrong value in Item No');
        Assert.AreEqual(LocationCode, ReservEntry."Location Code", 'Wrong value in Location Code');
        Assert.AreEqual(VariantCode, ReservEntry."Variant Code", 'Wrong value in Variant Code');
        Assert.AreEqual(Date, ReservEntry."Shipment Date", 'Wrong value in Shipment Date');
        Assert.AreEqual(QtyBase, ReservEntry."Quantity (Base)", 'Wrong value in Qty (Base)');
        Assert.AreEqual(Qty, ReservEntry.Quantity, 'Wrong value in Quantity');
        Assert.AreEqual(QtyPrUnit, ReservEntry."Qty. per Unit of Measure", 'Wrong value in Qty per UOM');

        // Reservation Status
        Assert.AreEqual(
          ReservEntry."Reservation Status"::Reservation, ReservEntry."Reservation Status",
          'Reservation Status should be Reservation');
    end;

    local procedure VerifyCalculatedFields(QtyExpected: Decimal; QtyActual: Decimal; QtyBaseExpected: Decimal; QtyBaseActual: Decimal)
    begin
        Assert.AreEqual(QtyExpected, QtyActual, 'The value in calculated field Reserved Quantity is wrong');
        Assert.AreEqual(QtyBaseExpected, QtyBaseActual, 'The value in calculated field Reserved Qty (Base) is wrong');
    end;

    local procedure CreateAsmLineResFromPurch(var AssemblyLine: Record "Assembly Line"; var PurchLine: Record "Purchase Line")
    var
        Item: Record Item;
        TrackingSpecification: Record "Tracking Specification";
        AssemblyLineReserve: Codeunit "Assembly Line-Reserve";
        AvailabilityDate: Date;
        QtyToReserve: Decimal;
        LocationCode: Code[10];
        VariantCode: Code[10];
    begin
        // Assembly Line reserved from Purchase Order Line
        MockItem(Item);
        LocationCode := IDcode10('l');
        VariantCode := IDcode10('v');
        AvailabilityDate := Today;
        QtyToReserve := 23;

        // Line to Reserv from
        MockPurchOrderLine(
          PurchLine, Item."No.", LocationCode, VariantCode, AvailabilityDate, QtyToReserve, QtyToReserve, 1, 10000);

        // Line to Reserv for
        MockAsmOrderLine(
          AssemblyLine, IDcode20('asm'), Item."No.", LocationCode, VariantCode, AvailabilityDate, QtyToReserve, QtyToReserve, 1, 10000);

        // Create Reservation Entry
        TrackingSpecification.InitTrackingSpecification(
          DATABASE::"Purchase Line",
          PurchLine."Document Type".AsInteger(),
          PurchLine."Document No.",
          '',
          0, PurchLine."Line No.",
          PurchLine."Variant Code",
          PurchLine."Location Code",
          PurchLine."Qty. per Unit of Measure");
        AssemblyLineReserve.CreateReservationSetFrom(TrackingSpecification);
        AssemblyLineReserve.CreateBindingReservation(
          AssemblyLine, PurchLine.Description, PurchLine."Expected Receipt Date",
          Round(QtyToReserve / AssemblyLine."Qty. per Unit of Measure", 0.00001),
          QtyToReserve);
    end;

    local procedure CreateAsmHdrResFromSalesLine(var AssemblyHeader: Record "Assembly Header"; var SalesLine: Record "Sales Line")
    var
        Item: Record Item;
        TrackingSpecification: Record "Tracking Specification";
        AsmHeaderReserve: Codeunit "Assembly Header-Reserve";
        AvailabilityDate: Date;
        QtyToReserve: Decimal;
        LocationCode: Code[10];
        VariantCode: Code[10];
    begin
        // Assembly Header reserved from Sales Line
        MockItem(Item);
        LocationCode := IDcode10('l');
        VariantCode := IDcode10('v');

        AvailabilityDate := Today;
        QtyToReserve := 23;

        // Line to Reserv from
        MockSalesOrderLine(SalesLine, Item."No.", LocationCode, VariantCode, AvailabilityDate, QtyToReserve, QtyToReserve, 1, 10000);

        // Line to Reserv for
        MockAsmOrderHeader(
          AssemblyHeader, IDcode20('asm'), Item."No.", LocationCode, VariantCode, AvailabilityDate, QtyToReserve, QtyToReserve, 1);

        // Create Reservation Entry
        TrackingSpecification.InitTrackingSpecification(
          DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", '', 0, SalesLine."Line No.",
          SalesLine."Variant Code", SalesLine."Location Code", SalesLine."Qty. per Unit of Measure");
        AsmHeaderReserve.CreateReservationSetFrom(TrackingSpecification);
        AsmHeaderReserve.CreateReservation(AssemblyHeader, 'Test', AvailabilityDate, 0, QtyToReserve);
    end;

    local procedure MockItem(var Item: Record Item)
    begin
        Item.Init();
        Item."No." := IDcode20('Kit');
        Item.Insert();
    end;

    local procedure MockSalesOrderLine(var SalesLine: Record "Sales Line"; ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; Date: Date; Qty: Decimal; RemainingQty: Decimal; QtyPrUnit: Decimal; LineNo: Integer)
    begin
        SalesLine.Init();
        SalesLine."Document Type" := SalesLine."Document Type"::Order;
        SalesLine."Document No." := IDcode20('so');
        SalesLine."Line No." := LineNo;
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine."No." := ItemNo;
        SalesLine."Location Code" := LocationCode;
        SalesLine."Variant Code" := VariantCode;
        SalesLine.Quantity := Qty;
        SalesLine."Outstanding Quantity" := RemainingQty;
        SalesLine."Quantity (Base)" := CalcBaseQty(SalesLine.Quantity, QtyPrUnit);
        SalesLine."Outstanding Qty. (Base)" := CalcBaseQty(SalesLine."Outstanding Quantity", QtyPrUnit);
        SalesLine."Shipment Date" := Date;
        SalesLine."Qty. per Unit of Measure" := QtyPrUnit;
        SalesLine.Insert();
    end;

    local procedure MockPurchOrderLine(var PurchLine: Record "Purchase Line"; ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; Date: Date; Qty: Decimal; RemainingQty: Decimal; QtyPrUnit: Decimal; LineNo: Integer)
    begin
        PurchLine.Init();
        PurchLine."Document Type" := PurchLine."Document Type"::Order;
        PurchLine."Document No." := IDcode20('pol');
        PurchLine."Line No." := LineNo;
        PurchLine.Type := PurchLine.Type::Item;
        PurchLine."No." := ItemNo;
        PurchLine."Location Code" := LocationCode;
        PurchLine."Variant Code" := VariantCode;
        PurchLine.Quantity := Qty;
        PurchLine."Outstanding Quantity" := RemainingQty;
        PurchLine."Quantity (Base)" := CalcBaseQty(PurchLine.Quantity, QtyPrUnit);
        PurchLine."Outstanding Qty. (Base)" := CalcBaseQty(PurchLine."Outstanding Quantity", QtyPrUnit);
        PurchLine."Expected Receipt Date" := Date;
        PurchLine."Qty. per Unit of Measure" := QtyPrUnit;
        PurchLine.Insert();
    end;

    local procedure MockAsmOrderHeader(var AssemblyHeader: Record "Assembly Header"; DocNo: Code[20]; ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; Date: Date; Qty: Decimal; RemainingQty: Decimal; QtyPrUnit: Decimal)
    begin
        MockAsmHeader(
          AssemblyHeader, DocNo, AssemblyHeader."Document Type"::Order,
          ItemNo, LocationCode, VariantCode, Date, Qty, RemainingQty, QtyPrUnit);
    end;

    local procedure MockAsmHeader(var AssemblyHeader: Record "Assembly Header"; DocNo: Code[20]; DocumentType: Enum "Assembly Document Type"; ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; Date: Date; Qty: Decimal; RemainingQty: Decimal; QtyPrUnit: Decimal)
    begin
        AssemblyHeader.Init();
        AssemblyHeader."Document Type" := DocumentType;
        AssemblyHeader."No." := DocNo;
        AssemblyHeader."Item No." := ItemNo;
        AssemblyHeader."Location Code" := LocationCode;
        AssemblyHeader."Variant Code" := VariantCode;
        AssemblyHeader."Due Date" := Date;
        AssemblyHeader.Quantity := Qty;
        AssemblyHeader."Remaining Quantity" := RemainingQty;
        AssemblyHeader."Quantity (Base)" := CalcBaseQty(AssemblyHeader.Quantity, QtyPrUnit);
        AssemblyHeader."Remaining Quantity (Base)" := CalcBaseQty(AssemblyHeader."Remaining Quantity", QtyPrUnit);
        AssemblyHeader."Qty. per Unit of Measure" := QtyPrUnit;
        AssemblyHeader.Insert();
    end;

    local procedure MockAsmOrderLine(var AssemblyLine: Record "Assembly Line"; DocNo: Code[20]; ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; Date: Date; Qty: Decimal; RemainingQty: Decimal; QtyPrUnit: Decimal; LineNo: Integer)
    begin
        AssemblyLine.Init();
        AssemblyLine."Document Type" := AssemblyLine."Document Type"::Order;
        AssemblyLine."Document No." := DocNo;
        AssemblyLine."Line No." := LineNo;
        AssemblyLine.Type := AssemblyLine.Type::Item;
        AssemblyLine."No." := ItemNo;
        AssemblyLine."Location Code" := LocationCode;
        AssemblyLine."Variant Code" := VariantCode;
        AssemblyLine."Due Date" := Date;
        AssemblyLine.Quantity := Qty;
        AssemblyLine."Remaining Quantity" := RemainingQty;
        AssemblyLine."Quantity (Base)" := CalcBaseQty(AssemblyLine.Quantity, QtyPrUnit);
        AssemblyLine."Remaining Quantity (Base)" := CalcBaseQty(AssemblyLine."Remaining Quantity", QtyPrUnit);
        AssemblyLine."Qty. per Unit of Measure" := QtyPrUnit;
        AssemblyLine.Insert();
    end;

    local procedure MockReservEntry(var ReservEntry: Record "Reservation Entry"; SourceType: Option "0","1","2","3","4","5","6","7","8","9","10"; SourceID: Code[20]; SourceSubType: Integer; SourceRefNo: Integer; QtyBase: Decimal; Qty: Decimal)
    begin
        ReservEntry.Init();
        ReservEntry."Source Type" := SourceType;
        ReservEntry."Source ID" := SourceID;
        ReservEntry."Source Subtype" := SourceSubType;
        ReservEntry."Source Ref. No." := SourceRefNo;
        ReservEntry."Quantity (Base)" := QtyBase;
        ReservEntry.Quantity := Qty;
        ReservEntry."Reservation Status" := ReservEntry."Reservation Status"::Reservation;
        ReservEntry."Entry No." := 0;
        ReservEntry.Insert();
    end;

    local procedure FindLastRerservationByLink(SourceType: Integer; SourceSubType: Integer; SourceID: Code[20]; SourceRefNo: Integer; var ReservEntry: Record "Reservation Entry"): Boolean
    begin
        ReservEntry.SetRange("Source Type", SourceType);
        ReservEntry.SetRange("Source Subtype", SourceSubType);
        ReservEntry.SetRange("Source ID", SourceID);
        ReservEntry.SetRange("Source Ref. No.", SourceRefNo);
        exit(ReservEntry.FindLast());
    end;

    local procedure CalcBaseQty(Qty: Decimal; QtyPerUnit: Decimal): Decimal
    begin
        if QtyPerUnit = 0 then
            exit(1);

        exit(Round(Qty * QtyPerUnit, 0.00001));
    end;

    local procedure IDcode20(Prefix: Code[5]): Code[20]
    begin
        // ID for test methods and mocking data.
        exit(Prefix + ID());
    end;

    local procedure IDcode10(Prefix: Code[2]): Code[10]
    begin
        // ID for test methods and mocking data.
        exit(Prefix + ID());
    end;

    local procedure ID(): Code[8]
    begin
        // ID is build on Day of the week and current time in XML format to make it independent of regional settings and locale
        exit(CurrentDayInWeek1to7() + CurrentTimeXMLFormat());
    end;

    local procedure CurrentDayInWeek1to7(): Code[1]
    begin
        exit(Format(Date2DWY(Today, 1)));
    end;

    local procedure CurrentTimeXMLFormat(): Code[7]
    var
        TimeStrXML: Text[30];
    begin
        TimeStrXML := Format(Time, 0, XMLFormat()); // Format: hh:mm::ss.milliseconds (16:55:48.253)

        exit(CopyStr(DelChr(TimeStrXML, '=', ':.'), 1, 7)); // Format: hhmmssmilliseconds (1655482)
    end;

    local procedure XMLFormat(): Integer
    begin
        exit(9);
    end;

    local procedure Contains(String: Text[250]; SubString: Text[250]): Boolean
    begin
        exit(StrPos(String, SubString) > 0);
    end;
}

