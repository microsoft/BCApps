// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Location;
using Microsoft.Inventory.Planning;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Routing;
using Microsoft.Purchases.Vendor;

codeunit 99001522 "Subc. Planning Comp. Ext."
{
    [EventSubscriber(ObjectType::Table, Database::"Planning Component", OnAfterValidateEvent, "Routing Link Code", false, false)]
    local procedure OnAfterValidateRoutingLinkCode(var Rec: Record "Planning Component"; var xRec: Record "Planning Component"; CurrFieldNo: Integer)
    begin
        HandleRoutingLinkCodeValidation(Rec, xRec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Planning Component", OnAfterTransferFromComponent, '', false, false)]
    local procedure OnAfterTransferFromComponent(var PlanningComponent: Record "Planning Component"; var ProdOrderComp: Record "Prod. Order Component")
    begin
        PlanningComponent."Subcontracting Type" := ProdOrderComp."Subcontracting Type";
        PlanningComponent."Orig. Location Code" := ProdOrderComp."Orig. Location Code";
        PlanningComponent."Orig. Bin Code" := ProdOrderComp."Orig. Bin Code";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Planning Component", OnAfterValidateEvent, "Location Code", false, false)]
    local procedure OnAfterValidateLocationCode(var Rec: Record "Planning Component"; var xRec: Record "Planning Component"; CurrFieldNo: Integer)
    begin
        if Rec."Location Code" <> xRec."Location Code" then
            Rec."Orig. Location Code" := xRec."Location Code";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Planning Component", OnAfterValidateEvent, "Bin Code", false, false)]
    local procedure OnAfterValidateBinCode(var Rec: Record "Planning Component"; var xRec: Record "Planning Component"; CurrFieldNo: Integer)
    begin
        if Rec."Bin Code" <> xRec."Bin Code" then
            Rec."Orig. Bin Code" := xRec."Bin Code";
    end;

    local procedure HandleRoutingLinkCodeValidation(var PlanningComponent: Record "Planning Component"; var xPlanningComponent: Record "Planning Component")
    var
        PlanningRoutingLine: Record "Planning Routing Line";
        StockkeepingUnit: Record "Stockkeeping Unit";
        Vendor: Record Vendor;
        PlanningGetParameters: Codeunit "Planning-Get Parameters";
        SubcontractingManagement: Codeunit "Subcontracting Management";
    begin
        if PlanningComponent."Routing Link Code" <> '' then begin
            PlanningRoutingLine.SetRange("Worksheet Template Name", PlanningComponent."Worksheet Template Name");
            PlanningRoutingLine.SetRange("Worksheet Batch Name", PlanningComponent."Worksheet Batch Name");
            PlanningRoutingLine.SetRange("Worksheet Line No.", PlanningComponent."Worksheet Line No.");
            PlanningRoutingLine.SetRange("Routing Link Code", PlanningComponent."Routing Link Code");
            PlanningRoutingLine.SetRange(Type, PlanningRoutingLine.Type::"Work Center");
            if PlanningRoutingLine.FindFirst() then
                if SubcontractingManagement.GetSubcontractor(PlanningRoutingLine."No.", Vendor) then
                    SubcontractingManagement.ChangeLocation_OnPlanningComponent(PlanningComponent, Vendor."Subcontr. Location Code", PlanningComponent."Orig. Location Code", PlanningComponent."Orig. Bin Code");
        end else
            if xPlanningComponent."Routing Link Code" <> '' then
                if PlanningComponent."Orig. Location Code" <> '' then begin
                    PlanningComponent.Validate("Location Code", PlanningComponent."Orig. Location Code");
                    PlanningComponent."Orig. Location Code" := '';
                    if PlanningComponent."Orig. Bin Code" <> '' then begin
                        PlanningComponent.Validate("Bin Code", PlanningComponent."Orig. Bin Code");
                        PlanningComponent."Orig. Bin Code" := '';
                    end;
                end else begin
                    PlanningGetParameters.AtSKU(
                      StockkeepingUnit,
                      PlanningComponent."Item No.",
                      PlanningComponent."Variant Code",
                      PlanningComponent."Location Code");
                    PlanningComponent.Validate(PlanningComponent."Location Code", StockkeepingUnit."Components at Location");
                end;
    end;

}