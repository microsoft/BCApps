// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Wizard;

using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;

codeunit 99001018 "Prod. Order Direct Creator"
{
    var
        ProdOrderCompRoutingCreated: Boolean;
        TempRecordNotFoundErr: Label 'No temporary %1 exists for source type %2. The wizard source must provide a %1 context before a production order can be created.', Comment = '%1 = record type (Production Order or Production Order Line), %2 = source type';

    /// <summary>
    /// Creates a Production Order from the temporary data held in TempData with the specified status.
    /// Returns the created production order.
    /// </summary>
    [CommitBehavior(CommitBehavior::Ignore)]
    internal procedure CreateProductionOrderFromTempData(var TempData: Codeunit "Prod. Definition Temp Data"; var ProdOrder: Record "Production Order")
    var
        ProdOrderLine: Record "Prod. Order Line";
        TempProdOrderLine: Record "Prod. Order Line" temporary;
    begin
        CreateProductionOrderFromTemp(ProdOrder, TempData);

        TempData.GetGlobalProdOrderLine(TempProdOrderLine);
        if not TempProdOrderLine.FindFirst() then
            RaiseTempRecordNotFoundError(TempProdOrderLine.TableCaption(), Format(TempData.GetGlobalSourceType()));

        CreateProdOrderLineFromTemp(ProdOrderLine, ProdOrder, TempProdOrderLine);
        TransferComponentsAndRoutingLines(ProdOrderLine, TempData);
    end;

    local procedure CreateProductionOrderFromTemp(var ProdOrder: Record "Production Order"; var TempData: Codeunit "Prod. Definition Temp Data")
    var
        TempProdOrder: Record "Production Order" temporary;
    begin
        TempData.GetGlobalProdOrder(TempProdOrder);
        if not TempProdOrder.FindFirst() then
            RaiseTempRecordNotFoundError(TempProdOrder.TableCaption(), Format(TempData.GetGlobalSourceType()));

        Clear(ProdOrder);
        ProdOrder.Init();
        ProdOrder.Validate(Status, TempProdOrder.Status);
        ProdOrder.Insert(true);
        ProdOrderCompRoutingCreated := false;

        ProdOrder."Due Date" := TempProdOrder."Due Date";
        ProdOrder."Starting Date" := TempProdOrder."Due Date";
        ProdOrder."Source Type" := TempProdOrder."Source Type";
        ProdOrder."Location Code" := TempProdOrder."Location Code";
        ProdOrder.Validate("Source No.", TempProdOrder."Source No.");
        ProdOrder.Validate("Variant Code", TempProdOrder."Variant Code");
        ProdOrder.Validate(Quantity, TempProdOrder.Quantity);
        OnConfigureProductionOrderFromTempOnBeforeModify(ProdOrder, TempProdOrder);
        ProdOrder.Modify(true);
    end;

    local procedure CreateProdOrderLineFromTemp(var ProdOrderLine: Record "Prod. Order Line"; ProdOrder: Record "Production Order"; TempProdOrderLine: Record "Prod. Order Line" temporary)
    var
        RecordFound: Boolean;
    begin
        ProdOrderLine.SetRange(Status, ProdOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrder."No.");
        RecordFound := ProdOrderLine.FindFirst();
        if not RecordFound then begin
            ProdOrderLine.Init();
            ProdOrderLine.Status := ProdOrder.Status;
            ProdOrderLine."Prod. Order No." := ProdOrder."No.";
            ProdOrderLine."Line No." := 10000;
            ProdOrderLine."Routing Reference No." := ProdOrderLine."Line No.";
        end;

        ProdOrderLine.Validate("Item No.", TempProdOrderLine."Item No.");
        ProdOrderLine."Location Code" := TempProdOrderLine."Location Code";
        ProdOrderLine.Validate("Variant Code", TempProdOrderLine."Variant Code");
        ProdOrderLine.Description := TempProdOrderLine.Description;
        ProdOrderLine."Description 2" := TempProdOrderLine."Description 2";
        ProdOrderLine."Shortcut Dimension 1 Code" := TempProdOrderLine."Shortcut Dimension 1 Code";
        ProdOrderLine."Shortcut Dimension 2 Code" := TempProdOrderLine."Shortcut Dimension 2 Code";
        ProdOrderLine."Dimension Set ID" := TempProdOrderLine."Dimension Set ID";
        ProdOrderLine.Validate(Quantity, TempProdOrderLine.Quantity);
        ProdOrderLine."Due Date" := TempProdOrderLine."Due Date";
        ProdOrderLine."Starting Date" := ProdOrder."Starting Date";
        ProdOrderLine."Starting Time" := ProdOrder."Starting Time";
        ProdOrderLine."Ending Date" := ProdOrder."Ending Date";
        ProdOrderLine."Ending Time" := ProdOrder."Ending Time";
        ProdOrderLine."Bin Code" := TempProdOrderLine."Bin Code";
        ProdOrderLine.UpdateDatetime();
        if TempProdOrderLine."Production BOM No." <> '' then
            ProdOrderLine."Production BOM No." := TempProdOrderLine."Production BOM No.";
        if TempProdOrderLine."Production BOM Version Code" <> '' then
            ProdOrderLine."Production BOM Version Code" := TempProdOrderLine."Production BOM Version Code";
        if TempProdOrderLine."Routing No." <> '' then
            ProdOrderLine."Routing No." := TempProdOrderLine."Routing No.";
        if TempProdOrderLine."Routing Version Code" <> '' then
            ProdOrderLine."Routing Version Code" := TempProdOrderLine."Routing Version Code";
        ProdOrderLine.Validate("Unit Cost");

        if RecordFound then
            ProdOrderLine.Modify(true)
        else
            ProdOrderLine.Insert(true);
    end;

    local procedure RaiseTempRecordNotFoundError(RecordCaption: Text; SourceType: Text)
    var
        TempRecordNotFoundErrorInfo: ErrorInfo;
    begin
        TempRecordNotFoundErrorInfo.DataClassification := DataClassification::SystemMetadata;
        TempRecordNotFoundErrorInfo.ErrorType := ErrorType::Internal;
        TempRecordNotFoundErrorInfo.Verbosity := Verbosity::Error;
        TempRecordNotFoundErrorInfo.Message := StrSubstNo(TempRecordNotFoundErr, RecordCaption, SourceType);
        Error(TempRecordNotFoundErrorInfo);
    end;

    local procedure TransferComponentsAndRoutingLines(var ProdOrderLine: Record "Prod. Order Line"; var TempData: Codeunit "Prod. Definition Temp Data")
    var
        TempBOMLine: Record "Production BOM Line" temporary;
        TempRoutingLine: Record "Routing Line" temporary;
    begin
        TempData.GetGlobalBOMLines(TempBOMLine);
        TempData.GetGlobalRoutingLines(TempRoutingLine);

        if TempBOMLine.IsEmpty() and TempRoutingLine.IsEmpty() then
            exit;

        TransferProductionOrderComponents(ProdOrderLine, TempData);
        TransferProductionOrderRoutingLines(ProdOrderLine, TempData);

        ProdOrderCompRoutingCreated := true;
    end;

    local procedure TransferProductionOrderComponents(var ProdOrderLine: Record "Prod. Order Line"; var TempData: Codeunit "Prod. Definition Temp Data")
    var
        ProdOrderComponent: Record "Prod. Order Component";
        TempProdOrderComponent: Record "Prod. Order Component" temporary;
    begin
        TempData.GetGlobalProdOrderComponent(TempProdOrderComponent);
        if TempProdOrderComponent.FindSet() then
            repeat
                CreateProdOrderComponentFromTemp(ProdOrderComponent, TempProdOrderComponent, ProdOrderLine);
            until TempProdOrderComponent.Next() = 0;
    end;

    local procedure CreateProdOrderComponentFromTemp(var ProdOrderComponent: Record "Prod. Order Component"; TempProdOrderComponent: Record "Prod. Order Component" temporary; ProdOrderLine: Record "Prod. Order Line")
    begin
        ProdOrderComponent.Init();
        ProdOrderComponent.Status := ProdOrderLine.Status;
        ProdOrderComponent."Prod. Order No." := ProdOrderLine."Prod. Order No.";
        ProdOrderComponent."Prod. Order Line No." := ProdOrderLine."Line No.";
        ProdOrderComponent."Line No." := TempProdOrderComponent."Line No.";
        ProdOrderComponent.Validate("Item No.", TempProdOrderComponent."Item No.");
        ProdOrderComponent.Validate("Unit of Measure Code", TempProdOrderComponent."Unit of Measure Code");
        ProdOrderComponent.Validate("Quantity per", TempProdOrderComponent."Quantity per");
        ProdOrderComponent.Validate("Routing Link Code", TempProdOrderComponent."Routing Link Code");
        ProdOrderComponent.Validate("Location Code", TempProdOrderComponent."Location Code");
        ProdOrderComponent.Validate("Variant Code", TempProdOrderComponent."Variant Code");
        ProdOrderComponent.Validate("Bin Code", TempProdOrderComponent."Bin Code");
        ProdOrderComponent.Validate("Flushing Method", TempProdOrderComponent."Flushing Method");
        ProdOrderComponent.Validate("Scrap %", TempProdOrderComponent."Scrap %");
        ProdOrderComponent.Validate("Calculation Formula", TempProdOrderComponent."Calculation Formula");
        ProdOrderComponent.Length := TempProdOrderComponent.Length;
        ProdOrderComponent.Width := TempProdOrderComponent.Width;
        ProdOrderComponent.Weight := TempProdOrderComponent.Weight;
        ProdOrderComponent.Depth := TempProdOrderComponent.Depth;
        ProdOrderComponent.Position := TempProdOrderComponent.Position;
        ProdOrderComponent."Position 2" := TempProdOrderComponent."Position 2";
        ProdOrderComponent."Position 3" := TempProdOrderComponent."Position 3";
        ProdOrderComponent."Lead-Time Offset" := TempProdOrderComponent."Lead-Time Offset";
        ProdOrderComponent.Description := TempProdOrderComponent.Description;
        ProdOrderComponent."Description 2" := TempProdOrderComponent."Description 2";
        OnBeforeInsertProdOrderComponentFromTemp(ProdOrderComponent, TempProdOrderComponent, ProdOrderLine);
        ProdOrderComponent.Insert(true);
    end;

    local procedure TransferProductionOrderRoutingLines(var ProdOrderLine: Record "Prod. Order Line"; var TempData: Codeunit "Prod. Definition Temp Data")
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        TempProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary;
    begin
        TempData.GetGlobalProdOrderRoutingLine(TempProdOrderRoutingLine);
        if TempProdOrderRoutingLine.FindSet() then
            repeat
                CreateProdOrderRoutingLineFromTemp(ProdOrderRoutingLine, TempProdOrderRoutingLine, ProdOrderLine);
            until TempProdOrderRoutingLine.Next() = 0;
    end;

    local procedure CreateProdOrderRoutingLineFromTemp(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; TempProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary; ProdOrderLine: Record "Prod. Order Line")
    begin
        ProdOrderRoutingLine.Init();
        ProdOrderRoutingLine.Status := ProdOrderLine.Status;
        ProdOrderRoutingLine."Prod. Order No." := ProdOrderLine."Prod. Order No.";
        ProdOrderRoutingLine."Routing No." := TempProdOrderRoutingLine."Routing No.";
        ProdOrderRoutingLine.Validate("Routing Reference No.", ProdOrderLine."Line No.");
        ProdOrderRoutingLine.Validate("Operation No.", TempProdOrderRoutingLine."Operation No.");
        ProdOrderRoutingLine."Starting Time" := ProdOrderLine."Starting Time";
        ProdOrderRoutingLine."Starting Date" := ProdOrderLine."Starting Date";
        ProdOrderRoutingLine."Ending Time" := ProdOrderLine."Ending Time";
        ProdOrderRoutingLine."Ending Date" := ProdOrderLine."Ending Date";
        ProdOrderRoutingLine.Insert(true);
        ProdOrderRoutingLine.Validate(Type, TempProdOrderRoutingLine.Type);
        ProdOrderRoutingLine.Validate("No.", TempProdOrderRoutingLine."No.");
        ProdOrderRoutingLine.Validate("Work Center No.", TempProdOrderRoutingLine."Work Center No.");
        ProdOrderRoutingLine.Description := TempProdOrderRoutingLine.Description;
        ProdOrderRoutingLine."Description 2" := TempProdOrderRoutingLine."Description 2";
        ProdOrderRoutingLine."Setup Time" := TempProdOrderRoutingLine."Setup Time";
        ProdOrderRoutingLine."Run Time" := TempProdOrderRoutingLine."Run Time";
        ProdOrderRoutingLine."Wait Time" := TempProdOrderRoutingLine."Wait Time";
        ProdOrderRoutingLine."Move Time" := TempProdOrderRoutingLine."Move Time";
        ProdOrderRoutingLine."Routing Link Code" := TempProdOrderRoutingLine."Routing Link Code";
        ProdOrderRoutingLine."Previous Operation No." := TempProdOrderRoutingLine."Previous Operation No.";
        ProdOrderRoutingLine."Next Operation No." := TempProdOrderRoutingLine."Next Operation No.";
        ProdOrderRoutingLine."Flushing Method" := TempProdOrderRoutingLine."Flushing Method";
        ProdOrderRoutingLine."Schedule Manually" := TempProdOrderRoutingLine."Schedule Manually";
        ProdOrderRoutingLine."Setup Time Unit of Meas. Code" := TempProdOrderRoutingLine."Setup Time Unit of Meas. Code";
        ProdOrderRoutingLine."Run Time Unit of Meas. Code" := TempProdOrderRoutingLine."Run Time Unit of Meas. Code";
        ProdOrderRoutingLine."Wait Time Unit of Meas. Code" := TempProdOrderRoutingLine."Wait Time Unit of Meas. Code";
        ProdOrderRoutingLine."Move Time Unit of Meas. Code" := TempProdOrderRoutingLine."Move Time Unit of Meas. Code";
        ProdOrderRoutingLine."Fixed Scrap Quantity" := TempProdOrderRoutingLine."Fixed Scrap Quantity";
        ProdOrderRoutingLine."Scrap Factor %" := TempProdOrderRoutingLine."Scrap Factor %";
        ProdOrderRoutingLine."Send-Ahead Quantity" := TempProdOrderRoutingLine."Send-Ahead Quantity";
        ProdOrderRoutingLine."Concurrent Capacities" := TempProdOrderRoutingLine."Concurrent Capacities";
        ProdOrderRoutingLine."Lot Size" := TempProdOrderRoutingLine."Lot Size";
        ProdOrderRoutingLine."Unit Cost per" := TempProdOrderRoutingLine."Unit Cost per";
        ProdOrderRoutingLine.Validate("Location Code", TempProdOrderRoutingLine."Location Code");
        ProdOrderRoutingLine.Validate("From-Production Bin Code", TempProdOrderRoutingLine."From-Production Bin Code");
        ProdOrderRoutingLine.Validate("To-Production Bin Code", TempProdOrderRoutingLine."To-Production Bin Code");
        ProdOrderRoutingLine.Validate("Open Shop Floor Bin Code", TempProdOrderRoutingLine."Open Shop Floor Bin Code");
        OnBeforeModifyProdOrderRoutingLineFromTemp(ProdOrderRoutingLine, TempProdOrderRoutingLine, ProdOrderLine);
        ProdOrderRoutingLine.Modify(true);
    end;
    /// <summary>
    /// Refreshes the production order.
    /// When components and routing lines were directly transferred from temporary data, only dates are
    /// recalculated (CalcRouting/CalcComponents = false). When no temporary transfer occurred, a full
    /// backwards explosion is performed using the item's saved BOM and routing (CalcRouting/CalcComponents = true),
    /// mirroring the standard production order creation path.
    /// </summary>
    internal procedure RefreshProductionOrder(var ProductionOrder: Record "Production Order")
    var
        ProdOrderLine: Record "Prod. Order Line";
        CalculateProdOrder: Codeunit "Calculate Prod. Order";
        Direction: Option Forward,Backward;
    begin
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        if not ProdOrderLine.FindFirst() then
            exit;
        if ProdOrderCompRoutingCreated then
            CalculateProdOrder.Calculate(ProdOrderLine, Direction::Backward, false, false, false, true)
        else
            CalculateProdOrder.Calculate(ProdOrderLine, Direction::Backward, true, true, true, true);
    end;
    /// <summary>
    /// Returns whether production order components and routing lines were created during the last direct creation run.
    /// </summary>
    /// <returns>True if components and routing lines were created; otherwise false.</returns>
    internal procedure GetProdOrderCompRoutingCreated(): Boolean
    begin
        exit(ProdOrderCompRoutingCreated);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertProdOrderComponentFromTemp(var ProdOrderComponent: Record "Prod. Order Component"; TempProdOrderComponent: Record "Prod. Order Component"; ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyProdOrderRoutingLineFromTemp(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; TempProdOrderRoutingLine: Record "Prod. Order Routing Line"; ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnConfigureProductionOrderFromTempOnBeforeModify(var ProdOrder: Record "Production Order"; TempProdOrder: Record "Production Order" temporary)
    begin
    end;
}