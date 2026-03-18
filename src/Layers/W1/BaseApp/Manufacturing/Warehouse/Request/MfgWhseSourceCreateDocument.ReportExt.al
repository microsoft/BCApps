// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Request;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Manufacturing.Document;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Journal;

reportextension 7305 "Mfg. WhseSourceCreateDocument" extends "Whse.-Source - Create Document"
{
    dataset
    {
        addafter("Whse. Internal Put-away Line")
        {
            dataitem("Prod. Order Component"; "Prod. Order Component")
            {
                DataItemTableView = sorting(Status, "Prod. Order No.", "Prod. Order Line No.", "Line No.");

                trigger OnAfterGetRecord()
                var
                    Item: Record Item;
                    Location: Record Location;
                    WMSMgt: Codeunit "WMS Management";
                    QtyToPick: Decimal;
                    QtyToPickBase: Decimal;
                    SkipProdOrderComp: Boolean;
                    EmptyGuid: Guid;
                begin
                    if "Prod. Order Component"."Location Code" <> '' then begin
                        Location.Get("Prod. Order Component"."Location Code");
                        if not (Location."Prod. Consump. Whse. Handling" in [Location."Prod. Consump. Whse. Handling"::"Warehouse Pick (mandatory)", Location."Prod. Consump. Whse. Handling"::"Warehouse Pick (optional)"]) then
                            CurrReport.Skip();
                    end;

                    FeatureTelemetry.LogUsage('0000KSZ', ProdAsmJobWhseHandlingTelemetryCategoryTok, ProdAsmJobWhseHandlingTelemetryTok);
                    if ("Flushing Method" = "Flushing Method"::"Pick + Forward") and ("Routing Link Code" = '') then
                        CurrReport.Skip();

                    Item.Get("Item No.");
                    if Item.IsNonInventoriableType() then
                        CurrReport.Skip();

                    if not CheckIfProdOrderCompMeetsReservedFromStockSetting("Remaining Qty. (Base)", ReservedFromStock) then
                        CurrReport.Skip();

                    WMSMgt.CheckInboundBlockedBin("Location Code", "Bin Code", "Item No.", "Variant Code", "Unit of Measure Code");

                    SkipProdOrderComp := false;
                    OnAfterGetRecordProdOrderComponent("Prod. Order Component", SkipProdOrderComp);
                    if SkipProdOrderComp then
                        CurrReport.Skip();

                    WhseWkshLine.SetRange("Source Line No.", "Prod. Order Line No.");
                    WhseWkshLine.SetRange("Source Subline No.", "Line No.");
                    if not WhseWkshLine.FindFirst() then begin
                        TestField("Qty. per Unit of Measure");
                        CalcFields("Pick Qty.");

                        QtyToPick := "Expected Quantity" - "Qty. Picked" - "Pick Qty.";
                        QtyToPickBase := UOMMgt.CalcBaseQty("Item No.", "Variant Code", "Unit of Measure Code", QtyToPick, "Qty. per Unit of Measure");

                        if QtyToPick > 0 then begin
                            CreatePick.SetCustomWhseSourceLine(
                                "Prod. Order Component", 1,
                                Database::"Prod. Order Component", Status.AsInteger(), "Prod. Order No.", "Prod. Order Line No.", "Line No.");
                            CreatePick.SetTempWhseItemTrkgLine(
                                "Prod. Order No.", Database::"Prod. Order Component", '', "Prod. Order Line No.", "Line No.", "Location Code");
                            CreatePick.CreateTempLine(
                                "Location Code", "Item No.", "Variant Code", "Unit of Measure Code", '', "Bin Code", "Qty. per Unit of Measure",
                                "Qty. Rounding Precision", "Qty. Rounding Precision (Base)", QtyToPick, QtyToPickBase);
                        end
                        else
                            CreatePick.InsertSkippedLinesToCalculationSummary(Database::"Prod. Order Component", "Prod. Order No.", "Prod. Order Line No.", Status.AsInteger(), "Line No.", "Location Code", "Item No.", "Variant Code", "Unit of Measure Code", "Bin Code", QtyToPick, QtyToPickBase, EmptyGuid);
                    end else begin
                        WhseWkshLineFound := true;
                        CreatePick.InsertSkippedLinesToCalculationSummary(Database::"Prod. Order Component", "Prod. Order No.", "Prod. Order Line No.", Status.AsInteger(), "Line No.", "Location Code", "Item No.", "Variant Code", "Unit of Measure Code", "Bin Code", Quantity, "Quantity (Base)", WhseWkshLine.SystemId);
                    end;
                end;

                trigger OnPreDataItem()
#if not CLEAN26
                var
                    ManufacturingSetup: Record Microsoft.Manufacturing.Setup."Manufacturing Setup";
#endif
                begin
                    if WhseDoc <> WhseDoc::Production then
                        CurrReport.Break();

                    WhseSetup.Get();

                    Clear(CreatePickParameters);
                    CreatePickParameters."Assigned ID" := AssignedID;
                    CreatePickParameters."Sorting Method" := SortActivity;
                    CreatePickParameters."Max No. of Lines" := 0;
                    CreatePickParameters."Max No. of Source Doc." := 0;
                    CreatePickParameters."Do Not Fill Qty. to Handle" := DoNotFillQtytoHandleReq;
                    CreatePickParameters."Breakbulk Filter" := BreakbulkFilter;
                    CreatePickParameters."Per Bin" := false;
                    CreatePickParameters."Per Zone" := false;
                    CreatePickParameters."Whse. Document" := CreatePickParameters."Whse. Document"::Production;
                    CreatePickParameters."Whse. Document Type" := CreatePickParameters."Whse. Document Type"::Pick;
                    CreatePick.SetParameters(CreatePickParameters);
                    CreatePick.SetSaveSummary(ShowSummary);

                    SetRange("Prod. Order No.", ProdOrderHeader."No.");
                    SetRange(Status, Status::Released);
#if not CLEAN26
                    if not ManufacturingSetup.IsFeatureKeyFlushingMethodManualWithoutPickEnabled() then
                        SetFilter(
                        "Flushing Method", '%1|%2|%3|%4',
                        "Flushing Method"::Manual,
                        "Flushing Method"::"Pick + Manual",
                        "Flushing Method"::"Pick + Forward",
                        "Flushing Method"::"Pick + Backward")
                    else
#endif
                        SetFilter(
                        "Flushing Method", '%1|%2|%3',
                        "Flushing Method"::"Pick + Manual",
                        "Flushing Method"::"Pick + Forward",
                        "Flushing Method"::"Pick + Backward");
                    SetRange("Planning Level Code", 0);
                    SetFilter("Expected Qty. (Base)", '>0');

                    WhseWkshLine.SetCurrentKey("Source Type", "Source Subtype", "Source No.", "Source Line No.", "Source Subline No.");
                    WhseWkshLine.SetRange("Source Type", Database::"Prod. Order Component");
                    WhseWkshLine.SetRange("Source Subtype", ProdOrderHeader.Status);
                    WhseWkshLine.SetRange("Source No.", ProdOrderHeader."No.");
                    OnAfterProdOrderComponentOnPreDataItem("Prod. Order Component");
                end;
            }
        }
    }

    var
        ProdOrderHeader: Record "Production Order";

    procedure SetProdOrder(var ProdOrderHeader2: Record "Production Order")
    var
        SortingMethod: Option;
    begin
        ProdOrderHeader.Copy(ProdOrderHeader2);
        WhseDoc := WhseDoc::Production;
        SourceLocationCode := ProdOrderHeader."Location Code";
        SourceTableCaption := ProdOrderHeader.TableCaption();

        SortingMethod := SortActivity.AsInteger();
        OnAfterSetProdOrder(ProdOrderHeader, SortingMethod);
        SortActivity := "Whse. Activity Sorting Method".FromInteger(SortingMethod);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetProdOrder(ProductionOrder: Record "Production Order"; var SortActivity: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProdOrderComponentOnPreDataItem(var ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordProdOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; var SkipProdOrderComp: Boolean)
    begin
    end;

}
