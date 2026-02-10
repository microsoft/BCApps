// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Routing;

codeunit 99001554 "Subc. TempProdOrdBind"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Subc. Temp Data Initializer", OnBeforeBuildTemporaryStructureFromBOMRouting, '', false, false)]
    local procedure "Sub. Temp Data Initializer_OnBeforeBuildTemporaryStructureFromBOMRouting"(SubcTempDataInitializer: Codeunit "Subc. Temp Data Initializer")
    var
        TempProdOrderLine: Record "Prod. Order Line" temporary;
        TempRoutingLine: Record "Routing Line" temporary;
    begin
        SubcTempDataInitializer.GetGlobalProdOrderLine(TempProdOrderLine);
        SubcTempDataInitializer.GetGlobalRoutingLines(TempRoutingLine);
        PrepareDummyProdOrderLine(TempProdOrderLine, TempRoutingLine."Routing No.");
    end;

    [EventSubscriber(ObjectType::Page, Page::"Subc. PurchProvisionWizard", OnClosePageEvent, '', false, false)]
    local procedure OnCloseBOMRtngWizard()
    begin
        DeleteDummyProdOrderLine();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Routing Line", OnBeforeCalcStartingEndingDates, '', false, false)]
    local procedure "Prod. Order Routing Line_OnBeforeCalcStartingEndingDates"(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var Direction: Option; var IsHandled: Boolean)
    begin
        if ProdOrderRoutingLine.IsTemporary() then
            IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Routing Line", OnBeforeCheckRoutingNoNotBlank, '', false, false)]
    local procedure "Prod. Order Routing Line_OnBeforeCheckRoutingNoNotBlank"(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var IsHandled: Boolean)
    begin
        if ProdOrderRoutingLine.IsTemporary() then
            IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Routing Line", OnBeforeDeleteEvent, '', false, false)]
    local procedure "Prod. Order Routing Line_OnBeforeDeleteEvent"(var Rec: Record "Prod. Order Routing Line")
    begin
        if Rec.IsTemporary() then
            PrepareDummyProdOrderRoutingLine(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Routing Line", OnAfterDeleteEvent, '', false, false)]
    local procedure "Prod. Order Routing Line_OnAfterDeleteEvent"(var Rec: Record "Prod. Order Routing Line")
    begin
        DeleteDummyProdOrderRoutingLine();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Routing Line", OnBeforeModifyEvent, '', false, false)]
    local procedure "Prod. Order Routing Line_OnBeforeModifyEvent"(var Rec: Record "Prod. Order Routing Line")
    begin
        if Rec.IsTemporary() then
            PrepareDummyProdOrderRoutingLine(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Routing Line", OnAfterModifyEvent, '', false, false)]
    local procedure "Prod. Order Routing Line_OnAfterModifyEvent"(var Rec: Record "Prod. Order Routing Line")
    begin
        if Rec.IsTemporary() then
            DeleteDummyProdOrderRoutingLine();
    end;

    var
        DummyProdOrderLine: Record "Prod. Order Line";
        DummyProdOrderRoutingLine: Record "Prod. Order Routing Line";

    procedure PrepareDummyProdOrderLine(var TempProdOrderLine: Record "Prod. Order Line" temporary; RoutingNo: Code[20])
    begin
        if not DummyProdOrderLine.Get(TempProdOrderLine.Status, TempProdOrderLine."Prod. Order No.", TempProdOrderLine."Line No.") then begin
            DummyProdOrderLine := TempProdOrderLine;
            DummyProdOrderLine."Routing No." := RoutingNo;
            DummyProdOrderLine.Insert()
        end else begin
            DummyProdOrderLine."Routing No." := RoutingNo;
            DummyProdOrderLine.Modify();
        end;
    end;

    procedure DeleteDummyProdOrderLine()
    begin
        if DummyProdOrderLine.Get(DummyProdOrderLine.Status, DummyProdOrderLine."Prod. Order No.", DummyProdOrderLine."Line No.") then
            DummyProdOrderLine.Delete();
    end;

    local procedure PrepareDummyProdOrderRoutingLine(ProdOrderRoutingLineToDelete: Record "Prod. Order Routing Line")
    begin
        if not DummyProdOrderRoutingLine.Get(ProdOrderRoutingLineToDelete.Status, ProdOrderRoutingLineToDelete."Prod. Order No.", ProdOrderRoutingLineToDelete."Routing Reference No.", ProdOrderRoutingLineToDelete."Routing No.", ProdOrderRoutingLineToDelete."Operation No.") then begin
            DummyProdOrderRoutingLine := ProdOrderRoutingLineToDelete;
            DummyProdOrderRoutingLine.Insert();
        end;
    end;

    local procedure DeleteDummyProdOrderRoutingLine()
    begin
        if DummyProdOrderRoutingLine.Get(DummyProdOrderRoutingLine.Status, DummyProdOrderRoutingLine."Prod. Order No.", DummyProdOrderRoutingLine."Routing Reference No.", DummyProdOrderRoutingLine."Routing No.", DummyProdOrderRoutingLine."Operation No.") then
            DummyProdOrderRoutingLine.Delete();
        Clear(DummyProdOrderRoutingLine);
    end;
}