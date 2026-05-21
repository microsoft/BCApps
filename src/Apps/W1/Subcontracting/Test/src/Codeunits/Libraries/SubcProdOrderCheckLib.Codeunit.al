// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Manufacturing.Document;
using Microsoft.Purchases.Document;

codeunit 139987 "Subc. ProdOrderCheckLib"
{
    var
        Assert: Codeunit Assert;
        Description2MismatchOnLineLbl: Label 'Description 2 mismatch on Line %1. Expected: %2, Actual: %3', Locked = true;
        Description2MismatchOnOperationLbl: Label 'Description 2 mismatch on Operation %1. Expected: %2, Actual: %3', Locked = true;
        DescriptionMismatchOnOperationLbl: Label 'Description mismatch on Operation %1. Expected: %2, Actual: %3', Locked = true;
        DirectUnitCostMismatchOnOperationLbl: Label 'Direct Unit Cost mismatch on Operation %1. Expected: %2, Actual: %3', Locked = true;
        DueDateMismatchOnLineLbl: Label 'Due Date mismatch on Line %1. Expected: %2, Actual: %3', Locked = true;
        ExpectedComponentsButFoundLbl: Label 'Expected %1 components, but found %2', Locked = true;
        ExpectedRoutingLinesButFoundLbl: Label 'Expected %1 routing lines, but found %2', Locked = true;
        FlushingMethodMismatchOnLineLbl: Label 'Flushing Method mismatch on Line %1. Expected: %2, Actual: %3', Locked = true;
        IndirectCostPercentMismatchOnOperationLbl: Label 'Indirect Cost %% mismatch on Operation %1. Expected: %2, Actual: %3', Locked = true;
        ItemNoMismatchOnLineLbl: Label 'Item No. mismatch on Line %1. Expected: %2, Actual: %3', Locked = true;
        LocationCodeMismatchOnLineLbl: Label 'Location Code mismatch on Line %1. Expected: %2, Actual: %3', Locked = true;
        NoMismatchOnOperationLbl: Label 'No. mismatch on Operation %1. Expected: %2, Actual: %3', Locked = true;
        OverheadRateMismatchOnOperationLbl: Label 'Overhead Rate mismatch on Operation %1. Expected: %2, Actual: %3', Locked = true;
        ProdOrderComponentWithLineNoNotFoundLbl: Label 'Production Order Component with Line No. %1 not found', Locked = true;
        ProdOrderRoutingLineWithOperationNoNotFoundLbl: Label 'Production Order Routing Line with Operation No. %1 not found', Locked = true;
        QuantityMismatchOnLineLbl: Label 'Quantity mismatch on Line %1. Expected: %2, Actual: %3', Locked = true;
        QuantityPerMismatchOnLineLbl: Label 'Quantity per mismatch on Line %1. Expected: %2, Actual: %3', Locked = true;
        RoutingLinkCodeMismatchOnLineLbl: Label 'Routing Link Code mismatch on Line %1. Expected: %2, Actual: %3', Locked = true;
        RoutingLinkCodeMismatchOnOperationLbl: Label 'Routing Link Code mismatch on Operation %1. Expected: %2, Actual: %3', Locked = true;
        RunTimeMismatchOnOperationLbl: Label 'Run Time mismatch on Operation %1. Expected: %2, Actual: %3', Locked = true;
        SetupTimeMismatchOnOperationLbl: Label 'Setup Time mismatch on Operation %1. Expected: %2, Actual: %3', Locked = true;
        TypeMismatchOnOperationLbl: Label 'Type mismatch on Operation %1. Expected: %2, Actual: %3', Locked = true;
        UnitCostCalculationMismatchOnOperationLbl: Label 'Unit Cost Calculation mismatch on Operation %1. Expected: %2, Actual: %3', Locked = true;
        WorkCenterGroupCodeMismatchOnOperationLbl: Label 'Work Center Group Code mismatch on Operation %1. Expected: %2, Actual: %3', Locked = true;
        WorkCenterNoMismatchOnOperationLbl: Label 'Work Center No. mismatch on Operation %1. Expected: %2, Actual: %3', Locked = true;

    procedure VerifyProdOrder(PurchLine: Record "Purchase Line"; var ProdOrder: Record "Production Order")
    begin
        PurchLine.SetLoadFields("Prod. Order No.", Quantity);
        PurchLine.Get(PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.");
        Assert.AreNotEqual('', PurchLine."Prod. Order No.", 'Production Order No. should be set on Purchase Line');

        ProdOrder.Get("Production Order Status"::Released, PurchLine."Prod. Order No.");
        Assert.AreEqual(PurchLine.Quantity, ProdOrder.Quantity, 'Production Order should have correct Quantity');
    end;

    procedure VerifyProdOrderComponentsMatchTempRecords(ProdOrder: Record "Production Order"; var TempProdOrderComponent: Record "Prod. Order Component" temporary)
    var
        ActualProdOrderComponent: Record "Prod. Order Component";
        ActualComponentCount: Integer;
        LineNo: Integer;
        TempComponentCount: Integer;
    begin
        // Count temporary components
        TempProdOrderComponent.Reset();
        TempComponentCount := TempProdOrderComponent.Count();

        // Count actual components
        ActualProdOrderComponent.SetRange(Status, ProdOrder.Status);
        ActualProdOrderComponent.SetRange("Prod. Order No.", ProdOrder."No.");
        ActualComponentCount := ActualProdOrderComponent.Count();

        // Verify counts match
        Assert.AreEqual(TempComponentCount, ActualComponentCount,
            StrSubstNo(ExpectedComponentsButFoundLbl, TempComponentCount, ActualComponentCount));

        // Verify each component in sequence
        TempProdOrderComponent.Reset();
        if TempProdOrderComponent.FindSet() then
            repeat
                LineNo := TempProdOrderComponent."Line No.";

                // Find corresponding actual component
                ActualProdOrderComponent.SetRange("Line No.", LineNo);
                Assert.IsTrue(ActualProdOrderComponent.FindFirst(),
                    StrSubstNo(ProdOrderComponentWithLineNoNotFoundLbl, LineNo));

                // Verify key fields match
                VerifyProdOrderComponentFields(TempProdOrderComponent, ActualProdOrderComponent);
            until TempProdOrderComponent.Next() = 0;
    end;

    local procedure VerifyProdOrderComponentFields(TempComponent: Record "Prod. Order Component" temporary; ActualComponent: Record "Prod. Order Component")
    begin
        // Verify essential fields match between temporary and actual component
        Assert.AreEqual(TempComponent."Item No.", ActualComponent."Item No.",
            StrSubstNo(ItemNoMismatchOnLineLbl,
                TempComponent."Line No.", TempComponent."Item No.", ActualComponent."Item No."));

        Assert.AreEqual(TempComponent."Flushing Method", ActualComponent."Flushing Method",
            StrSubstNo(FlushingMethodMismatchOnLineLbl,
                TempComponent."Line No.", TempComponent."Flushing Method", ActualComponent."Flushing Method"));

        Assert.AreEqual(TempComponent."Routing Link Code", ActualComponent."Routing Link Code",
            StrSubstNo(RoutingLinkCodeMismatchOnLineLbl,
                TempComponent."Line No.", TempComponent."Routing Link Code", ActualComponent."Routing Link Code"));

        Assert.AreEqual(TempComponent."Location Code", ActualComponent."Location Code",
            StrSubstNo(LocationCodeMismatchOnLineLbl,
                TempComponent."Line No.", TempComponent."Location Code", ActualComponent."Location Code"));

        // Verify quantities if set in temporary record
        if TempComponent."Quantity per" <> 0 then
            Assert.AreEqual(TempComponent."Quantity per", ActualComponent."Quantity per",
                StrSubstNo(QuantityPerMismatchOnLineLbl,
                    TempComponent."Line No.", TempComponent."Quantity per", ActualComponent."Quantity per"));

        if TempComponent.Quantity <> 0 then
            Assert.AreEqual(TempComponent.Quantity, ActualComponent.Quantity,
                StrSubstNo(QuantityMismatchOnLineLbl,
                    TempComponent."Line No.", TempComponent.Quantity, ActualComponent.Quantity));

        // Verify dates if set in temporary record
        if TempComponent."Due Date" <> 0D then
            Assert.AreEqual(TempComponent."Due Date", ActualComponent."Due Date",
                StrSubstNo(DueDateMismatchOnLineLbl,
                    TempComponent."Line No.", TempComponent."Due Date", ActualComponent."Due Date"));

        // Verify Description 2 if set in temporary record
        if TempComponent."Description 2" <> '' then
            Assert.AreEqual(TempComponent."Description 2", ActualComponent."Description 2",
                StrSubstNo(Description2MismatchOnLineLbl,
                    TempComponent."Line No.", TempComponent."Description 2", ActualComponent."Description 2"));
    end;

    procedure VerifyProdOrderRoutingLinesMatchTempRecords(ProdOrder: Record "Production Order"; var TempProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary)
    var
        ActualProdOrderRoutingLine: Record "Prod. Order Routing Line";
        OperationNo: Code[10];
        ActualRoutingCount: Integer;
        TempRoutingCount: Integer;
    begin
        // Count temporary routing lines
        TempProdOrderRoutingLine.Reset();
        TempRoutingCount := TempProdOrderRoutingLine.Count();

        // Count actual routing lines
        ActualProdOrderRoutingLine.SetRange(Status, ProdOrder.Status);
        ActualProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrder."No.");
        ActualRoutingCount := ActualProdOrderRoutingLine.Count();

        // Verify counts match
        Assert.AreEqual(TempRoutingCount, ActualRoutingCount,
            StrSubstNo(ExpectedRoutingLinesButFoundLbl, TempRoutingCount, ActualRoutingCount));

        // Verify each routing line in sequence
        TempProdOrderRoutingLine.Reset();
        if TempProdOrderRoutingLine.FindSet() then
            repeat
                OperationNo := TempProdOrderRoutingLine."Operation No.";

                // Find corresponding actual routing line
                ActualProdOrderRoutingLine.SetRange("Operation No.", OperationNo);
                Assert.IsTrue(ActualProdOrderRoutingLine.FindFirst(),
                    StrSubstNo(ProdOrderRoutingLineWithOperationNoNotFoundLbl, OperationNo));

                // Verify key fields match
                VerifyProdOrderRoutingLineFields(TempProdOrderRoutingLine, ActualProdOrderRoutingLine);
            until TempProdOrderRoutingLine.Next() = 0;
    end;

    local procedure VerifyProdOrderRoutingLineFields(TempRoutingLine: Record "Prod. Order Routing Line" temporary; ActualRoutingLine: Record "Prod. Order Routing Line")
    begin
        // Verify essential fields match between temporary and actual routing line
        Assert.AreEqual(TempRoutingLine.Type, ActualRoutingLine.Type,
            StrSubstNo(TypeMismatchOnOperationLbl,
                TempRoutingLine."Operation No.", TempRoutingLine.Type, ActualRoutingLine.Type));

        Assert.AreEqual(TempRoutingLine."No.", ActualRoutingLine."No.",
            StrSubstNo(NoMismatchOnOperationLbl,
                TempRoutingLine."Operation No.", TempRoutingLine."No.", ActualRoutingLine."No."));

        Assert.AreEqual(TempRoutingLine."Work Center No.", ActualRoutingLine."Work Center No.",
            StrSubstNo(WorkCenterNoMismatchOnOperationLbl,
                TempRoutingLine."Operation No.", TempRoutingLine."Work Center No.", ActualRoutingLine."Work Center No."));

        Assert.AreEqual(TempRoutingLine."Routing Link Code", ActualRoutingLine."Routing Link Code",
            StrSubstNo(RoutingLinkCodeMismatchOnOperationLbl,
                TempRoutingLine."Operation No.", TempRoutingLine."Routing Link Code", ActualRoutingLine."Routing Link Code"));

        // Verify Work Center Group Code if set
        if TempRoutingLine."Work Center Group Code" <> '' then
            Assert.AreEqual(TempRoutingLine."Work Center Group Code", ActualRoutingLine."Work Center Group Code",
                StrSubstNo(WorkCenterGroupCodeMismatchOnOperationLbl,
                    TempRoutingLine."Operation No.", TempRoutingLine."Work Center Group Code", ActualRoutingLine."Work Center Group Code"));

        // Verify Unit Cost Calculation if set
        Assert.AreEqual(TempRoutingLine."Unit Cost Calculation", ActualRoutingLine."Unit Cost Calculation",
            StrSubstNo(UnitCostCalculationMismatchOnOperationLbl,
                TempRoutingLine."Operation No.", TempRoutingLine."Unit Cost Calculation", ActualRoutingLine."Unit Cost Calculation"));

        // Verify cost fields if set in temporary record
        if TempRoutingLine."Direct Unit Cost" <> 0 then
            Assert.AreEqual(TempRoutingLine."Direct Unit Cost", ActualRoutingLine."Direct Unit Cost",
                StrSubstNo(DirectUnitCostMismatchOnOperationLbl,
                    TempRoutingLine."Operation No.", TempRoutingLine."Direct Unit Cost", ActualRoutingLine."Direct Unit Cost"));

        if TempRoutingLine."Indirect Cost %" <> 0 then
            Assert.AreEqual(TempRoutingLine."Indirect Cost %", ActualRoutingLine."Indirect Cost %",
                StrSubstNo(IndirectCostPercentMismatchOnOperationLbl,
                    TempRoutingLine."Operation No.", TempRoutingLine."Indirect Cost %", ActualRoutingLine."Indirect Cost %"));

        if TempRoutingLine."Overhead Rate" <> 0 then
            Assert.AreEqual(TempRoutingLine."Overhead Rate", ActualRoutingLine."Overhead Rate",
                StrSubstNo(OverheadRateMismatchOnOperationLbl,
                    TempRoutingLine."Operation No.", TempRoutingLine."Overhead Rate", ActualRoutingLine."Overhead Rate"));

        // Verify time fields if set in temporary record
        if TempRoutingLine."Setup Time" <> 0 then
            Assert.AreEqual(TempRoutingLine."Setup Time", ActualRoutingLine."Setup Time",
                StrSubstNo(SetupTimeMismatchOnOperationLbl,
                    TempRoutingLine."Operation No.", TempRoutingLine."Setup Time", ActualRoutingLine."Setup Time"));

        if TempRoutingLine."Run Time" <> 0 then
            Assert.AreEqual(TempRoutingLine."Run Time", ActualRoutingLine."Run Time",
                StrSubstNo(RunTimeMismatchOnOperationLbl,
                    TempRoutingLine."Operation No.", TempRoutingLine."Run Time", ActualRoutingLine."Run Time"));

        // Verify description if set
        if TempRoutingLine.Description <> '' then
            Assert.AreEqual(TempRoutingLine.Description, ActualRoutingLine.Description,
                StrSubstNo(DescriptionMismatchOnOperationLbl,
                    TempRoutingLine."Operation No.", TempRoutingLine.Description, ActualRoutingLine.Description));

        // Verify Description 2 if set in temporary record
        if TempRoutingLine."Description 2" <> '' then
            Assert.AreEqual(TempRoutingLine."Description 2", ActualRoutingLine."Description 2",
                StrSubstNo(Description2MismatchOnOperationLbl,
                    TempRoutingLine."Operation No.", TempRoutingLine."Description 2", ActualRoutingLine."Description 2"));
    end;
}