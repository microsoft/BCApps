// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Planning;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Purchases.Document;

codeunit 5455 "Supply What-If Planning Engine"
{
    var
        CannotFindImpactedDocumentsErr: Label 'Cannot find impacted documents. Please make sure the document line you are simulating on has reservations and try again.';
        NoChangesToSimulateErr: Label 'Change the What-If Quantity or the What-If Date before running the analysis.';
        WhatIfQuantityTooLargeErr: Label 'The What-If Quantity cannot be greater than the Original Quantity.';
        WhatIfDateTooEarlyErr: Label 'The What-If Date cannot be earlier than the Original Date.';

    internal procedure OpenWhatIfPlanning(Record: Variant)
    var
        TempWhatIfScenario: Record "Supply What-If Scenario" temporary;
        WhatIfScenariosPage: Page "Supply What-If Scenarios";
    begin
        TempWhatIfScenario.CreateScenario(Record);
        WhatIfScenariosPage.SetData(TempWhatIfScenario);
        WhatIfScenariosPage.RunModal();
    end;

    [CommitBehavior(CommitBehavior::Ignore)]
    internal procedure RunWhatIfAnalysis(var TempWhatIfScenario: Record "Supply What-If Scenario" temporary; var TempWhatIfImpact: Record "What-If Impact" temporary)
    var
        RequisitionLine: Record "Requisition Line";
        FindReservationEntry: Record "Reservation Entry";
        ItemsToAnalyze: List of [Code[20]];
    begin
        if (TempWhatIfScenario."What-If Quantity" = TempWhatIfScenario."Original Quantity") and
           (TempWhatIfScenario."What-If Date" = TempWhatIfScenario."Original Date")
        then
            Error(NoChangesToSimulateErr);

        if TempWhatIfScenario."What-If Quantity" > TempWhatIfScenario."Original Quantity" then
            Error(WhatIfQuantityTooLargeErr);

        if TempWhatIfScenario."What-If Date" < TempWhatIfScenario."Original Date" then
            Error(WhatIfDateTooEarlyErr);

        RequisitionLine.SetRange("Worksheet Template Name", CopyStr(UserId(), 1, 10));
        RequisitionLine.SetFilter("Journal Batch Name", '%1', '');
        RequisitionLine.SetRange("No.", TempWhatIfScenario."Item No.");
        if not RequisitionLine.IsEmpty() then
            RequisitionLine.DeleteAll(true);

        TempWhatIfImpact.Reset();
        TempWhatIfImpact.DeleteAll();

        UpdateTableRecord(TempWhatIfScenario);

        AddItemToList(TempWhatIfScenario."Item No.", ItemsToAnalyze);

        FindReservationEntry.SetSourceFilter(TempWhatIfScenario."Document Table No.", TempWhatIfScenario."Document Type", TempWhatIfScenario."Document No.", TempWhatIfScenario."Document Line No.", false);
        FindReservationEntry.SetRange(Positive, true);
        OnRunWhatIfAnalysisOnAfterSetFilters(TempWhatIfScenario, FindReservationEntry);
        if FindReservationEntry.FindSet() then
            repeat
                InsertWhatIfFromOutboundReservations(TempWhatIfImpact, FindReservationEntry);
            until FindReservationEntry.Next() = 0
        else
            SimulatePlanningAndFindReservations(TempWhatIfImpact, TempWhatIfScenario);
    end;

    local procedure SimulatePlanningAndFindReservations(var TempWhatIfImpact: Record "What-If Impact" temporary; var TempWhatIfScenario: Record "Supply What-If Scenario" temporary)
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        FindReservationEntry: Record "Reservation Entry";
        CarryOutActionMsgPlan: Report "Carry Out Action Msg. - Plan.";
    begin
        Item.SetRange("No.", TempWhatIfScenario."Item No.");
        Item.FindFirst();
        OnSimulatePlanningOnRunCalcItemPlan(TempWhatIfScenario, Item, CopyStr(UserId(), 1, 10));

        RequisitionLine.SetRange("Worksheet Template Name", CopyStr(UserId(), 1, 10));
        RequisitionLine.SetFilter("Journal Batch Name", '%1', '');
        RequisitionLine.SetRange("No.", TempWhatIfScenario."Item No.");
        RequisitionLine.SetFilter("Action Message", '<>%1', RequisitionLine."Action Message"::"Change Qty.");
        RequisitionLine.DeleteAll(true);

        RequisitionLine.SetRange("Action Message", RequisitionLine."Action Message"::"Change Qty.");
        if RequisitionLine.FindSet() then begin
            RequisitionLine.ModifyAll("Accept Action Message", true);

            CarryOutActionMsgPlan.SetSimulationMode(true);
            CarryOutActionMsgPlan.SetPlanningResiliency(true);
            CarryOutActionMsgPlan.UseRequestPage(false);
            CarryOutActionMsgPlan.SetReqWkshLine(RequisitionLine);
            CarryOutActionMsgPlan.InitializeRequest(
                Enum::Microsoft.Manufacturing.Document."Planning Create Prod. Order"::"Firm Planned".AsInteger(),
                Enum::"Planning Create Purchase Order"::"Make Purch. Orders".AsInteger(),
                Enum::"Planning Create Transfer Order"::"Make Trans. Orders".AsInteger(),
                Enum::"Planning Create Assembly Order"::"Make Assembly Orders".AsInteger());
            CarryOutActionMsgPlan.Run();
        end;

        FindReservationEntry.SetSourceFilter(TempWhatIfScenario."Document Table No.", TempWhatIfScenario."Document Type", TempWhatIfScenario."Document No.", TempWhatIfScenario."Document Line No.", false);
        FindReservationEntry.SetRange(Positive, true);
        OnSimulatePlanningAndFindReservationsOnAfterSetFilters(TempWhatIfScenario, FindReservationEntry);
        if not FindReservationEntry.FindSet() then
            Error(CannotFindImpactedDocumentsErr);

        repeat
            InsertWhatIfFromOutboundReservations(TempWhatIfImpact, FindReservationEntry);
        until FindReservationEntry.Next() = 0;
    end;

    local procedure InsertWhatIfFromOutboundReservations(var TempWhatIfImpact: Record "What-If Impact" temporary; InboundReservationEntry: Record "Reservation Entry")
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Entry No.", InboundReservationEntry."Entry No.");
        ReservationEntry.SetRange(Positive, false);
        if ReservationEntry.FindSet() then
            repeat
                InsertWhatIfImpact(ReservationEntry, TempWhatIfImpact);
            until ReservationEntry.Next() = 0;
    end;

    local procedure InsertWhatIfImpact(ReservationEntry: Record "Reservation Entry"; var TempWhatIfImpact: Record "What-If Impact" temporary)
    var
        TableId: Integer;
        DocumentLineNo: Integer;
        ImpactedItemNo: Code[20];
        IsHandled: Boolean;
    begin
        OnBeforeInsertWhatIfImpact(ReservationEntry, TableId, DocumentLineNo, ImpactedItemNo, IsHandled);
        if not IsHandled then begin
            TableId := ReservationEntry."Source Type";
            DocumentLineNo := ReservationEntry."Source Ref. No.";
            ImpactedItemNo := ReservationEntry."Item No.";
        end;

        TempWhatIfImpact.Init();
        TempWhatIfImpact."Entry No." := TempWhatIfImpact."Entry No." + 1;
        TempWhatIfImpact."Impact Table Id" := TableId;
        TempWhatIfImpact."Document No." := ReservationEntry."Source ID";
        TempWhatIfImpact."Document Line No." := DocumentLineNo;
        TempWhatIfImpact."Document Status" := ReservationEntry."Source Subtype";

        TempWhatIfImpact."Impacted Item No." := ImpactedItemNo;
        TempWhatIfImpact."Document Quantity (Base)" := ReservationEntry."Quantity (Base)";
        TempWhatIfImpact."Description" := ReservationEntry.Description;

        TempWhatIfImpact.Insert();
    end;

    local procedure UpdateTableRecord(TempWhatIfScenario: Record "Supply What-If Scenario")
    var
        IsHandled: Boolean;
    begin
        OnBeforeUpdateTableRecord(TempWhatIfScenario, IsHandled);
        if IsHandled then
            exit;

        case TempWhatIfScenario."Document Table No." of
            Database::"Purchase Line":
                UpdatePurchaseLine(TempWhatIfScenario);
            Database::"Transfer Line":
                UpdateTransferLine(TempWhatIfScenario);
        end;
    end;

    local procedure UpdatePurchaseLine(TempWhatIfScenario: Record "Supply What-If Scenario")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.Get(Enum::"Purchase Document Type".FromInteger(TempWhatIfScenario."Document Type"), TempWhatIfScenario."Document No.", TempWhatIfScenario."Document Line No.");
        if TempWhatIfScenario."What-If Quantity" <> PurchaseLine.Quantity then
            PurchaseLine.Quantity := TempWhatIfScenario."What-If Quantity";

        if TempWhatIfScenario."What-If Date" <> PurchaseLine."Expected Receipt Date" then
            PurchaseLine."Expected Receipt Date" := TempWhatIfScenario."What-If Date";

        PurchaseLine.Modify();
    end;

    local procedure UpdateTransferLine(TempWhatIfScenario: Record "Supply What-If Scenario")
    var
        TransferLine: Record "Transfer Line";
    begin
        TransferLine.Get(TempWhatIfScenario."Document No.", TempWhatIfScenario."Document Line No.");
        if TempWhatIfScenario."What-If Quantity" <> TransferLine.Quantity then
            TransferLine.Quantity := TempWhatIfScenario."What-If Quantity";

        if TempWhatIfScenario."What-If Date" <> TransferLine."Receipt Date" then
            TransferLine."Receipt Date" := TempWhatIfScenario."What-If Date";

        TransferLine.Modify();
    end;

    local procedure AddItemToList(ItemNo: Code[20]; var ItemsToAnalyze: List of [Code[20]])
    var
        Item: Record Item;
    begin
        if ItemsToAnalyze.Contains(ItemNo) then
            exit;

        Item.SetLoadFields("Production BOM No.");
        Item.Get(ItemNo);
        ItemsToAnalyze.Add(ItemNo);

        OnAddItemToListOnAfterAddItem(ItemNo, Item, ItemsToAnalyze);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunWhatIfAnalysisOnAfterSetFilters(var TempWhatIfScenario: Record "Supply What-If Scenario" temporary; var FindReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSimulatePlanningAndFindReservationsOnAfterSetFilters(var TempWhatIfScenario: Record "Supply What-If Scenario" temporary; var FindReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertWhatIfImpact(ReservationEntry: Record "Reservation Entry"; var TableId: Integer; var DocumentLineNo: Integer; var ImpactedItemNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateTableRecord(var TempWhatIfScenario: Record "Supply What-If Scenario" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddItemToListOnAfterAddItem(ItemNo: Code[20]; var Item: Record Item; var ItemsToAnalyze: List of [Code[20]])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSimulatePlanningOnRunCalcItemPlan(var TempWhatIfScenario: Record "Supply What-If Scenario" temporary; var Item: Record Item; WorksheetTemplateName: Code[10])
    begin
    end;
}