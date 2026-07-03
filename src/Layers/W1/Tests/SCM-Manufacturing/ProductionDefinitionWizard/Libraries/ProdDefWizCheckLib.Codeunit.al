// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Test;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Sales.Document;

codeunit 137422 "Prod. Def. Wiz. Check Lib."
{
    var
        Assert: Codeunit Assert;
        ItemShouldHaveBOMLbl: Label 'Item %1 should have BOM No. = %2', Locked = true;
        ItemShouldHaveRoutingLbl: Label 'Item %1 should have Routing No. = %2', Locked = true;
        SKUShouldHaveBOMLbl: Label 'SKU (%1/%2/%3) should have BOM No. = %4', Locked = true;
        ProdOrderShouldExistLbl: Label 'Production Order should exist for item %1', Locked = true;
        ProdOrderShouldNotExistLbl: Label 'No Production Order should exist for item %1', Locked = true;
        ProdOrderFieldMismatchLbl: Label 'Production Order field %1: expected %2, got %3', Locked = true;
        ComponentCountMismatchLbl: Label 'Expected %1 Prod. Order components but found %2', Locked = true;
        RoutingLineCountMismatchLbl: Label 'Expected %1 Prod. Order routing lines but found %2', Locked = true;
        BOMVersionShouldBeCertifiedLbl: Label 'BOM %1 version %2 should be certified', Locked = true;
        BOMVersionShouldNotExistLbl: Label 'BOM %1 version %2 should not exist', Locked = true;
        RoutingVersionShouldBeCertifiedLbl: Label 'Routing %1 version %2 should be certified', Locked = true;
        RoutingVersionShouldNotExistLbl: Label 'Routing Version should not exist for Routing %1', Locked = true;
        BOMVersionShouldBeNewLbl: Label 'BOM %1 should have a new version after the wizard; previous: %2, last is still: %3', Locked = true;
        RoutingVersionShouldBeNewLbl: Label 'Routing %1 should have a new version after the wizard; previous: %2, last is still: %3', Locked = true;
        ReservationShouldExistLbl: Label 'Reservation Entry should exist for Sales Line %1/%2', Locked = true;
        ReservationShouldNotExistLbl: Label 'Reservation Entry should NOT exist for Sales Line %1/%2', Locked = true;
        ReservationShouldLinkProdOrderLbl: Label 'Reservation Entry should exist linking Sales Line %1/%2 to Production Order %3', Locked = true;

    procedure VerifyItemHasBOM(ItemNo: Code[20]; ExpectedBOMNo: Code[20])
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        Assert.AreEqual(ExpectedBOMNo, Item."Production BOM No.",
            StrSubstNo(ItemShouldHaveBOMLbl, ItemNo, ExpectedBOMNo));
    end;

    procedure VerifyItemHasRouting(ItemNo: Code[20]; ExpectedRoutingNo: Code[20])
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        Assert.AreEqual(ExpectedRoutingNo, Item."Routing No.",
            StrSubstNo(ItemShouldHaveRoutingLbl, ItemNo, ExpectedRoutingNo));
    end;

    procedure VerifyItemBOMUnchanged(ItemNo: Code[20]; OriginalBOMNo: Code[20])
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        Assert.AreEqual(OriginalBOMNo, Item."Production BOM No.",
            StrSubstNo(ItemShouldHaveBOMLbl, ItemNo, OriginalBOMNo));
    end;

    procedure VerifyItemRoutingUnchanged(ItemNo: Code[20]; OriginalRoutingNo: Code[20])
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        Assert.AreEqual(OriginalRoutingNo, Item."Routing No.",
            StrSubstNo(ItemShouldHaveRoutingLbl, ItemNo, OriginalRoutingNo));
    end;

    procedure VerifyItemHasAnyBOM(ItemNo: Code[20])
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        Assert.AreNotEqual('', Item."Production BOM No.",
            StrSubstNo(ItemShouldHaveBOMLbl, ItemNo, '<non-empty>'));
    end;

    procedure VerifyItemHasAnyRouting(ItemNo: Code[20])
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        Assert.AreNotEqual('', Item."Routing No.",
            StrSubstNo(ItemShouldHaveRoutingLbl, ItemNo, '<non-empty>'));
    end;

    procedure VerifySKUHasBOM(ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; ExpectedBOMNo: Code[20])
    var
        SKU: Record "Stockkeeping Unit";
    begin
        SKU.Get(LocationCode, ItemNo, VariantCode);
        Assert.AreEqual(ExpectedBOMNo, SKU."Production BOM No.",
            StrSubstNo(SKUShouldHaveBOMLbl, ItemNo, LocationCode, VariantCode, ExpectedBOMNo));
    end;

    procedure VerifyNoProdOrderForItem(ItemNo: Code[20])
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange("Item No.", ItemNo);
        Assert.IsTrue(ProdOrderLine.IsEmpty(),
            StrSubstNo(ProdOrderShouldNotExistLbl, ItemNo));
    end;

    procedure VerifyProdOrderExists(ItemNo: Code[20]; var ProdOrder: Record "Production Order")
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange("Item No.", ItemNo);
        Assert.IsTrue(ProdOrderLine.FindFirst(),
            StrSubstNo(ProdOrderShouldExistLbl, ItemNo));
        ProdOrder.Get(ProdOrderLine.Status, ProdOrderLine."Prod. Order No.");
    end;

    procedure VerifyProdOrderFields(ProdOrder: Record "Production Order"; ItemNo: Code[20]; Qty: Decimal; DueDate: Date; LocationCode: Code[10]; VariantCode: Code[10])
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange(Status, ProdOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrder."No.");
        ProdOrderLine.SetRange("Item No.", ItemNo);
        Assert.IsTrue(ProdOrderLine.FindFirst(),
            StrSubstNo(ProdOrderShouldExistLbl, ItemNo));

        Assert.AreEqual(ItemNo, ProdOrderLine."Item No.",
            StrSubstNo(ProdOrderFieldMismatchLbl, 'Item No.', ItemNo, ProdOrderLine."Item No."));
        Assert.AreNearlyEqual(Qty, ProdOrderLine.Quantity, 0.01,
            StrSubstNo(ProdOrderFieldMismatchLbl, 'Quantity', Qty, ProdOrderLine.Quantity));
        if DueDate <> 0D then
            Assert.AreEqual(DueDate, ProdOrderLine."Due Date",
                StrSubstNo(ProdOrderFieldMismatchLbl, 'Due Date', DueDate, ProdOrderLine."Due Date"));
        Assert.AreEqual(LocationCode, ProdOrderLine."Location Code",
            StrSubstNo(ProdOrderFieldMismatchLbl, 'Location Code', LocationCode, ProdOrderLine."Location Code"));
        Assert.AreEqual(VariantCode, ProdOrderLine."Variant Code",
            StrSubstNo(ProdOrderFieldMismatchLbl, 'Variant Code', VariantCode, ProdOrderLine."Variant Code"));
    end;

    procedure VerifyProdOrderHasComponentCount(ProdOrder: Record "Production Order"; ExpectedCount: Integer)
    var
        ProdOrderComponent: Record "Prod. Order Component";
        ActualCount: Integer;
    begin
        ProdOrderComponent.SetRange(Status, ProdOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrder."No.");
        ActualCount := ProdOrderComponent.Count();
        Assert.AreEqual(ExpectedCount, ActualCount,
            StrSubstNo(ComponentCountMismatchLbl, ExpectedCount, ActualCount));
    end;

    procedure VerifyProdOrderHasRoutingLineCount(ProdOrder: Record "Production Order"; ExpectedCount: Integer)
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ActualCount: Integer;
    begin
        ProdOrderRoutingLine.SetRange(Status, ProdOrder.Status);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrder."No.");
        ActualCount := ProdOrderRoutingLine.Count();
        Assert.AreEqual(ExpectedCount, ActualCount,
            StrSubstNo(RoutingLineCountMismatchLbl, ExpectedCount, ActualCount));
    end;

    procedure VerifyNoBOMVersionExists(BOMNo: Code[20])
    var
        ProductionBOMVersion: Record "Production BOM Version";
    begin
        ProductionBOMVersion.SetRange("Production BOM No.", BOMNo);
        Assert.IsTrue(ProductionBOMVersion.IsEmpty(),
            StrSubstNo(BOMVersionShouldNotExistLbl, BOMNo, '<any>'));
    end;

    procedure VerifyNoRoutingVersionExists(RoutingNo: Code[20])
    var
        RoutingVersion: Record "Routing Version";
    begin
        RoutingVersion.SetRange("Routing No.", RoutingNo);
        Assert.IsTrue(RoutingVersion.IsEmpty(),
            StrSubstNo(RoutingVersionShouldNotExistLbl, RoutingNo));
    end;

    procedure GetLastBOMVersionCode(BOMNo: Code[20]): Code[20]
    var
        ProductionBOMVersion: Record "Production BOM Version";
    begin
        ProductionBOMVersion.SetRange("Production BOM No.", BOMNo);
        if ProductionBOMVersion.FindLast() then
            exit(ProductionBOMVersion."Version Code");
        exit('');
    end;

    procedure GetLastRoutingVersionCode(RoutingNo: Code[20]): Code[20]
    var
        RoutingVersion: Record "Routing Version";
    begin
        RoutingVersion.SetRange("Routing No.", RoutingNo);
        if RoutingVersion.FindLast() then
            exit(RoutingVersion."Version Code");
        exit('');
    end;

    procedure VerifyNewLastBOMVersionCertified(BOMNo: Code[20]; PreviousVersionCode: Code[20])
    var
        ProductionBOMVersion: Record "Production BOM Version";
    begin
        ProductionBOMVersion.SetRange("Production BOM No.", BOMNo);
        Assert.IsTrue(ProductionBOMVersion.FindLast(),
            StrSubstNo(BOMVersionShouldBeCertifiedLbl, BOMNo, '<new>'));
        Assert.AreNotEqual(PreviousVersionCode, ProductionBOMVersion."Version Code",
            StrSubstNo(BOMVersionShouldBeNewLbl, BOMNo, PreviousVersionCode, ProductionBOMVersion."Version Code"));
        Assert.AreEqual(ProductionBOMVersion.Status::Certified, ProductionBOMVersion.Status,
            StrSubstNo(BOMVersionShouldBeCertifiedLbl, BOMNo, ProductionBOMVersion."Version Code"));
    end;

    procedure VerifyNewLastRoutingVersionCertified(RoutingNo: Code[20]; PreviousVersionCode: Code[20])
    var
        RoutingVersion: Record "Routing Version";
    begin
        RoutingVersion.SetRange("Routing No.", RoutingNo);
        Assert.IsTrue(RoutingVersion.FindLast(),
            StrSubstNo(RoutingVersionShouldBeCertifiedLbl, RoutingNo, '<new>'));
        Assert.AreNotEqual(PreviousVersionCode, RoutingVersion."Version Code",
            StrSubstNo(RoutingVersionShouldBeNewLbl, RoutingNo, PreviousVersionCode, RoutingVersion."Version Code"));
        Assert.AreEqual(RoutingVersion.Status::Certified, RoutingVersion.Status,
            StrSubstNo(RoutingVersionShouldBeCertifiedLbl, RoutingNo, RoutingVersion."Version Code"));
    end;

    procedure VerifyReservationExistsForSalesLine(SalesLine: Record "Sales Line")
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Source Type", Database::"Sales Line");
        ReservationEntry.SetRange("Source Subtype", SalesLine."Document Type".AsInteger());
        ReservationEntry.SetRange("Source ID", SalesLine."Document No.");
        ReservationEntry.SetRange("Source Ref. No.", SalesLine."Line No.");
        Assert.IsFalse(ReservationEntry.IsEmpty(),
            StrSubstNo(ReservationShouldExistLbl, SalesLine."Document No.", SalesLine."Line No."));
    end;

    procedure VerifyReservationLinksToProductionOrder(SalesLine: Record "Sales Line"; ProdOrder: Record "Production Order")
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        // Verify the supply side of the reservation points to the specific Production Order
        ReservationEntry.SetRange("Source Type", Database::"Prod. Order Line");
        ReservationEntry.SetRange("Source Subtype", ProdOrder.Status.AsInteger());
        ReservationEntry.SetRange("Source ID", ProdOrder."No.");
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Reservation);
        Assert.IsFalse(ReservationEntry.IsEmpty(),
            StrSubstNo(ReservationShouldLinkProdOrderLbl,
                SalesLine."Document No.", SalesLine."Line No.", ProdOrder."No."));
    end;

    procedure VerifyProdOrderStatus(ProdOrder: Record "Production Order"; ExpectedStatus: Enum "Production Order Status")
    begin
        Assert.AreEqual(ExpectedStatus, ProdOrder.Status,
            StrSubstNo(ProdOrderFieldMismatchLbl, 'Status', Format(ExpectedStatus), Format(ProdOrder.Status)));
    end;

    procedure VerifyProdOrderLineHasBOM(ItemNo: Code[20]; ExpectedBOMNo: Code[20])
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange("Item No.", ItemNo);
        Assert.IsTrue(ProdOrderLine.FindFirst(),
            StrSubstNo(ProdOrderShouldExistLbl, ItemNo));
        Assert.AreEqual(ExpectedBOMNo, ProdOrderLine."Production BOM No.",
            StrSubstNo(ProdOrderFieldMismatchLbl, 'Production BOM No.', ExpectedBOMNo, ProdOrderLine."Production BOM No."));
    end;

    procedure VerifyProdOrderLineHasRouting(ItemNo: Code[20]; ExpectedRoutingNo: Code[20])
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange("Item No.", ItemNo);
        Assert.IsTrue(ProdOrderLine.FindFirst(),
            StrSubstNo(ProdOrderShouldExistLbl, ItemNo));
        Assert.AreEqual(ExpectedRoutingNo, ProdOrderLine."Routing No.",
            StrSubstNo(ProdOrderFieldMismatchLbl, 'Routing No.', ExpectedRoutingNo, ProdOrderLine."Routing No."));
    end;

    procedure VerifyProdOrderLineHasBOMVersion(ItemNo: Code[20]; ExpectedVersionCode: Code[20])
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange("Item No.", ItemNo);
        Assert.IsTrue(ProdOrderLine.FindFirst(),
            StrSubstNo(ProdOrderShouldExistLbl, ItemNo));
        Assert.AreEqual(ExpectedVersionCode, ProdOrderLine."Production BOM Version Code",
            StrSubstNo(ProdOrderFieldMismatchLbl, 'Production BOM Version Code', ExpectedVersionCode, ProdOrderLine."Production BOM Version Code"));
    end;

    procedure VerifyProdOrderLineHasRoutingVersion(ItemNo: Code[20]; ExpectedVersionCode: Code[20])
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange("Item No.", ItemNo);
        Assert.IsTrue(ProdOrderLine.FindFirst(),
            StrSubstNo(ProdOrderShouldExistLbl, ItemNo));
        Assert.AreEqual(ExpectedVersionCode, ProdOrderLine."Routing Version Code",
            StrSubstNo(ProdOrderFieldMismatchLbl, 'Routing Version Code', ExpectedVersionCode, ProdOrderLine."Routing Version Code"));
    end;

    procedure VerifyProdOrderLineScrapPct(ItemNo: Code[20]; ExpectedScrapPct: Decimal)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange("Item No.", ItemNo);
        Assert.IsTrue(ProdOrderLine.FindFirst(),
            StrSubstNo(ProdOrderShouldExistLbl, ItemNo));
        Assert.AreNearlyEqual(ExpectedScrapPct, ProdOrderLine."Scrap %", 0.01,
            StrSubstNo(ProdOrderFieldMismatchLbl, 'Scrap %', Format(ExpectedScrapPct), Format(ProdOrderLine."Scrap %")));
    end;

    procedure VerifyProdOrderComponentHasQtyPerForFirstComponent(ProdOrder: Record "Production Order"; ExpectedQtyPer: Decimal)
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent.SetRange(Status, ProdOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrder."No.");
        Assert.IsTrue(ProdOrderComponent.FindFirst(),
            StrSubstNo(ComponentCountMismatchLbl, 1, 0));
        Assert.AreNearlyEqual(ExpectedQtyPer, ProdOrderComponent."Quantity per", 0.01,
            StrSubstNo(ProdOrderFieldMismatchLbl, 'Quantity per', Format(ExpectedQtyPer), Format(ProdOrderComponent."Quantity per")));
    end;

    procedure VerifyProdOrderRoutingLineRunTime(ProdOrder: Record "Production Order"; OperationNo: Code[10]; ExpectedRunTime: Decimal)
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        ProdOrderRoutingLine.SetRange(Status, ProdOrder.Status);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrder."No.");
        ProdOrderRoutingLine.SetRange("Operation No.", OperationNo);
        Assert.IsTrue(ProdOrderRoutingLine.FindFirst(),
            StrSubstNo(RoutingLineCountMismatchLbl, 1, 0));
        Assert.AreNearlyEqual(ExpectedRunTime, ProdOrderRoutingLine."Run Time", 0.01,
            StrSubstNo(ProdOrderFieldMismatchLbl, 'Run Time', Format(ExpectedRunTime), Format(ProdOrderRoutingLine."Run Time")));
    end;

    procedure VerifyProdOrderComponentHasVariantCode(ProdOrder: Record "Production Order"; ExpectedVariantCode: Code[10])
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent.SetRange(Status, ProdOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrder."No.");
        Assert.IsTrue(ProdOrderComponent.FindFirst(),
            StrSubstNo(ComponentCountMismatchLbl, 1, 0));
        Assert.AreEqual(ExpectedVariantCode, ProdOrderComponent."Variant Code",
            StrSubstNo(ProdOrderFieldMismatchLbl, 'Variant Code (Component)', ExpectedVariantCode, ProdOrderComponent."Variant Code"));
    end;

    procedure VerifyProdOrderComponentHasDescription2(ProdOrder: Record "Production Order"; ExpectedDesc2: Text[50])
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent.SetRange(Status, ProdOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrder."No.");
        Assert.IsTrue(ProdOrderComponent.FindFirst(),
            StrSubstNo(ComponentCountMismatchLbl, 1, 0));
        Assert.AreEqual(ExpectedDesc2, ProdOrderComponent."Description 2",
            StrSubstNo(ProdOrderFieldMismatchLbl, 'Description 2', ExpectedDesc2, ProdOrderComponent."Description 2"));
    end;

    procedure VerifyProdOrderRoutingLineHasDescription2(ProdOrder: Record "Production Order"; ExpectedDesc2: Text[50])
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        ProdOrderRoutingLine.SetRange(Status, ProdOrder.Status);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrder."No.");
        Assert.IsTrue(ProdOrderRoutingLine.FindFirst(),
            StrSubstNo(RoutingLineCountMismatchLbl, 1, 0));
        Assert.AreEqual(ExpectedDesc2, ProdOrderRoutingLine."Description 2",
            StrSubstNo(ProdOrderFieldMismatchLbl, 'Description 2', ExpectedDesc2, ProdOrderRoutingLine."Description 2"));
    end;

    procedure VerifyProdOrderComponentFlushingMethod(ProdOrder: Record "Production Order"; ExpectedFlushingMethod: Enum "Flushing Method")
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent.SetRange(Status, ProdOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrder."No.");
        if ProdOrderComponent.FindSet() then
            repeat
                Assert.AreEqual(ExpectedFlushingMethod, ProdOrderComponent."Flushing Method",
                    StrSubstNo(ProdOrderFieldMismatchLbl, 'Flushing Method',
                        Format(ExpectedFlushingMethod), Format(ProdOrderComponent."Flushing Method")));
            until ProdOrderComponent.Next() = 0;
    end;

    procedure VerifyReservationBaseQtyMatchesProdOrderRemainingBase(SalesLine: Record "Sales Line"; ItemNo: Code[20])
    var
        ReservationEntry: Record "Reservation Entry";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange("Item No.", ItemNo);
        Assert.IsTrue(ProdOrderLine.FindFirst(),
            StrSubstNo(ProdOrderShouldExistLbl, ItemNo));
        ReservationEntry.SetRange("Source Type", Database::"Sales Line");
        ReservationEntry.SetRange("Source Subtype", SalesLine."Document Type".AsInteger());
        ReservationEntry.SetRange("Source ID", SalesLine."Document No.");
        ReservationEntry.SetRange("Source Ref. No.", SalesLine."Line No.");
        Assert.IsTrue(ReservationEntry.FindFirst(),
            StrSubstNo(ReservationShouldExistLbl, SalesLine."Document No.", SalesLine."Line No."));
        Assert.IsTrue(Abs(ReservationEntry."Quantity (Base)") > 0,
            'Reservation base quantity should be greater than zero');
        Assert.AreNearlyEqual(ProdOrderLine."Remaining Qty. (Base)", Abs(ReservationEntry."Quantity (Base)"), 0.01,
            StrSubstNo(ProdOrderFieldMismatchLbl,
                'Reservation Quantity (Base)',
                Format(ProdOrderLine."Remaining Qty. (Base)"),
                Format(Abs(ReservationEntry."Quantity (Base)"))));
    end;

    procedure VerifyTrackingSpecExistsForProdOrderLine(ItemNo: Code[20]; ExpectedLotNo: Code[50])
    var
        ProdOrderLine: Record "Prod. Order Line";
        ReservationEntry: Record "Reservation Entry";
    begin
        ProdOrderLine.SetRange("Item No.", ItemNo);
        Assert.IsTrue(ProdOrderLine.FindFirst(),
            StrSubstNo(ProdOrderShouldExistLbl, ItemNo));
        ReservationEntry.SetRange("Source Type", Database::"Prod. Order Line");
        ReservationEntry.SetRange("Source Subtype", ProdOrderLine.Status.AsInteger());
        ReservationEntry.SetRange("Source ID", ProdOrderLine."Prod. Order No.");
        ReservationEntry.SetRange("Source Prod. Order Line", ProdOrderLine."Line No.");
        Assert.IsTrue(ReservationEntry.FindFirst(),
            'Reservation Entry should exist for Prod. Order Line of item ' + ItemNo);
        Assert.AreEqual(ExpectedLotNo, ReservationEntry."Lot No.",
            'Lot No. on Reservation Entry should match expected: ' + ExpectedLotNo);
    end;

    procedure VerifyBOMVersionLineCount(BOMNo: Code[20]; VersionCode: Code[20]; ExpectedCount: Integer)
    var
        ProductionBOMLine: Record "Production BOM Line";
        ActualCount: Integer;
    begin
        ProductionBOMLine.SetRange("Production BOM No.", BOMNo);
        ProductionBOMLine.SetRange("Version Code", VersionCode);
        ActualCount := ProductionBOMLine.Count();
        Assert.AreEqual(ExpectedCount, ActualCount,
            StrSubstNo('BOM %1 version %2: expected %3 lines but found %4',
                BOMNo, VersionCode, ExpectedCount, ActualCount));
    end;

    procedure VerifyRoutingVersionLineCount(RoutingNo: Code[20]; VersionCode: Code[20]; ExpectedCount: Integer)
    var
        RoutingLine: Record "Routing Line";
        ActualCount: Integer;
    begin
        RoutingLine.SetRange("Routing No.", RoutingNo);
        RoutingLine.SetRange("Version Code", VersionCode);
        ActualCount := RoutingLine.Count();
        Assert.AreEqual(ExpectedCount, ActualCount,
            StrSubstNo('Routing %1 version %2: expected %3 lines but found %4',
                RoutingNo, VersionCode, ExpectedCount, ActualCount));
    end;

    procedure GetLastProductionBOMNo(): Code[20]
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        ProductionBOMHeader.SetLoadFields("No.");
        if ProductionBOMHeader.FindLast() then
            exit(ProductionBOMHeader."No.");
        exit('');
    end;

    procedure GetLastRoutingNo(): Code[20]
    var
        RoutingHeader: Record "Routing Header";
    begin
        RoutingHeader.SetLoadFields("No.");
        if RoutingHeader.FindLast() then
            exit(RoutingHeader."No.");
        exit('');
    end;

    procedure VerifyProdOrderComponentBOMFields(ProdOrder: Record "Production Order"; ComponentItemNo: Code[20]; ExpectedScrapPct: Decimal; ExpectedLength: Decimal; ExpectedWidth: Decimal; ExpectedWeight: Decimal; ExpectedDepth: Decimal)
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent.SetRange(Status, ProdOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrder."No.");
        ProdOrderComponent.SetRange("Item No.", ComponentItemNo);
        Assert.IsTrue(ProdOrderComponent.FindFirst(),
            StrSubstNo(ComponentCountMismatchLbl, 1, 0));
        Assert.AreNearlyEqual(ExpectedScrapPct, ProdOrderComponent."Scrap %", 0.01,
            StrSubstNo(ProdOrderFieldMismatchLbl, 'Scrap % (Component)', Format(ExpectedScrapPct), Format(ProdOrderComponent."Scrap %")));
        Assert.AreNearlyEqual(ExpectedLength, ProdOrderComponent."Length", 0.01,
            StrSubstNo(ProdOrderFieldMismatchLbl, 'Length (Component)', Format(ExpectedLength), Format(ProdOrderComponent."Length")));
        Assert.AreNearlyEqual(ExpectedWidth, ProdOrderComponent."Width", 0.01,
            StrSubstNo(ProdOrderFieldMismatchLbl, 'Width (Component)', Format(ExpectedWidth), Format(ProdOrderComponent."Width")));
        Assert.AreNearlyEqual(ExpectedWeight, ProdOrderComponent."Weight", 0.01,
            StrSubstNo(ProdOrderFieldMismatchLbl, 'Weight (Component)', Format(ExpectedWeight), Format(ProdOrderComponent."Weight")));
        Assert.AreNearlyEqual(ExpectedDepth, ProdOrderComponent."Depth", 0.01,
            StrSubstNo(ProdOrderFieldMismatchLbl, 'Depth (Component)', Format(ExpectedDepth), Format(ProdOrderComponent."Depth")));
    end;

    procedure VerifyProdOrderComponentCalcFormula(ProdOrder: Record "Production Order"; ComponentItemNo: Code[20])
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent.SetRange(Status, ProdOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrder."No.");
        ProdOrderComponent.SetRange("Item No.", ComponentItemNo);
        Assert.IsTrue(ProdOrderComponent.FindFirst(),
            StrSubstNo(ComponentCountMismatchLbl, 1, 0));
        Assert.AreEqual(
            ProdOrderComponent."Calculation Formula"::"Fixed Quantity",
            ProdOrderComponent."Calculation Formula",
            StrSubstNo(ProdOrderFieldMismatchLbl, 'Calculation Formula (Component)',
                Format(ProdOrderComponent."Calculation Formula"::"Fixed Quantity"),
                Format(ProdOrderComponent."Calculation Formula")));
    end;

    procedure VerifyProdOrderRoutingLineExtendedFields(ProdOrder: Record "Production Order"; OperationNo: Code[10]; ExpectedPrevOpNo: Code[30]; ExpectedNextOpNo: Code[30]; ExpectedSetupUOM: Code[10]; ExpectedRunUOM: Code[10]; ExpectedWaitUOM: Code[10]; ExpectedMoveUOM: Code[10]; ExpectedFixedScrapQty: Decimal; ExpectedScrapFactorPct: Decimal; ExpectedSendAheadQty: Decimal; ExpectedConcurrentCap: Decimal; ExpectedLotSize: Decimal)
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        ProdOrderRoutingLine.SetRange(Status, ProdOrder.Status);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrder."No.");
        ProdOrderRoutingLine.SetRange("Operation No.", OperationNo);
        Assert.IsTrue(ProdOrderRoutingLine.FindFirst(),
            StrSubstNo(RoutingLineCountMismatchLbl, 1, 0));
        Assert.AreEqual(ExpectedPrevOpNo, ProdOrderRoutingLine."Previous Operation No.",
            StrSubstNo(ProdOrderFieldMismatchLbl, 'Previous Operation No.', ExpectedPrevOpNo, ProdOrderRoutingLine."Previous Operation No."));
        Assert.AreEqual(ExpectedNextOpNo, ProdOrderRoutingLine."Next Operation No.",
            StrSubstNo(ProdOrderFieldMismatchLbl, 'Next Operation No.', ExpectedNextOpNo, ProdOrderRoutingLine."Next Operation No."));
        Assert.AreEqual(ExpectedSetupUOM, ProdOrderRoutingLine."Setup Time Unit of Meas. Code",
            StrSubstNo(ProdOrderFieldMismatchLbl, 'Setup Time Unit of Meas. Code', ExpectedSetupUOM, ProdOrderRoutingLine."Setup Time Unit of Meas. Code"));
        Assert.AreEqual(ExpectedRunUOM, ProdOrderRoutingLine."Run Time Unit of Meas. Code",
            StrSubstNo(ProdOrderFieldMismatchLbl, 'Run Time Unit of Meas. Code', ExpectedRunUOM, ProdOrderRoutingLine."Run Time Unit of Meas. Code"));
        Assert.AreEqual(ExpectedWaitUOM, ProdOrderRoutingLine."Wait Time Unit of Meas. Code",
            StrSubstNo(ProdOrderFieldMismatchLbl, 'Wait Time Unit of Meas. Code', ExpectedWaitUOM, ProdOrderRoutingLine."Wait Time Unit of Meas. Code"));
        Assert.AreEqual(ExpectedMoveUOM, ProdOrderRoutingLine."Move Time Unit of Meas. Code",
            StrSubstNo(ProdOrderFieldMismatchLbl, 'Move Time Unit of Meas. Code', ExpectedMoveUOM, ProdOrderRoutingLine."Move Time Unit of Meas. Code"));
        Assert.AreNearlyEqual(ExpectedFixedScrapQty, ProdOrderRoutingLine."Fixed Scrap Quantity", 0.01,
            StrSubstNo(ProdOrderFieldMismatchLbl, 'Fixed Scrap Quantity', Format(ExpectedFixedScrapQty), Format(ProdOrderRoutingLine."Fixed Scrap Quantity")));
        Assert.AreNearlyEqual(ExpectedScrapFactorPct, ProdOrderRoutingLine."Scrap Factor %", 0.01,
            StrSubstNo(ProdOrderFieldMismatchLbl, 'Scrap Factor %', Format(ExpectedScrapFactorPct), Format(ProdOrderRoutingLine."Scrap Factor %")));
        Assert.AreNearlyEqual(ExpectedSendAheadQty, ProdOrderRoutingLine."Send-Ahead Quantity", 0.01,
            StrSubstNo(ProdOrderFieldMismatchLbl, 'Send-Ahead Quantity', Format(ExpectedSendAheadQty), Format(ProdOrderRoutingLine."Send-Ahead Quantity")));
        Assert.AreNearlyEqual(ExpectedConcurrentCap, ProdOrderRoutingLine."Concurrent Capacities", 0.01,
            StrSubstNo(ProdOrderFieldMismatchLbl, 'Concurrent Capacities', Format(ExpectedConcurrentCap), Format(ProdOrderRoutingLine."Concurrent Capacities")));
        Assert.AreNearlyEqual(ExpectedLotSize, ProdOrderRoutingLine."Lot Size", 0.01,
            StrSubstNo(ProdOrderFieldMismatchLbl, 'Lot Size', Format(ExpectedLotSize), Format(ProdOrderRoutingLine."Lot Size")));
    end;
}