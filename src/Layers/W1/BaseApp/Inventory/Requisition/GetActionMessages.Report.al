// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Requisition;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Inventory.Setup;
using Microsoft.Purchases.Document;


report 99001023 "Get Action Messages"
{
    Caption = 'Get Action Messages';
    ProcessingOnly = true;

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = sorting("Low-Level Code") where("Order Tracking Policy" = const("Tracking & Action Msg."));
            RequestFilterFields = "No.", "Search Description";

            trigger OnAfterGetRecord()
            begin
                Window.Update(1, Text001);
                Window.Update(2, "No.");

                if "Order Tracking Policy" <> "Order Tracking Policy"::"Tracking & Action Msg." then
                    CurrReport.Skip();
                ReqLineExtern.SetRange(Type, ReqLineExtern.Type::Item);
                ReqLineExtern.SetRange("No.", "No.");
                if ReqLineExtern.FindFirst() then begin
                    TempItemInOtherWksh := Item;
                    TempItemInOtherWksh.Insert();
                    CurrReport.Skip();
                end;

                ActionMessageEntry.SetRange("Item No.", "No.");
                if ActionMessageEntry.Find('-') then
                    repeat
                        ActionMessageEntry.SetSourceFilterFromActionEntry(ActionMessageEntry);
                        ActionMessageEntry.SetRange("Location Code", ActionMessageEntry."Location Code");
                        ActionMessageEntry.SetRange("Bin Code", ActionMessageEntry."Bin Code");
                        ActionMessageEntry.SetRange("Variant Code", ActionMessageEntry."Variant Code");
                        if ActionMessageEntry."Source ID" = '' then begin
                            TempNewActionMsgEntry.DeleteAll();
                            repeat
                                TrkgReservEntry.Get(ActionMessageEntry."Reservation Entry", false);
                                if TempNewActionMsgEntry.Get(
                                     TrkgReservEntry."Shipment Date" - 19000101D)
                                then begin // Generate Entry No. in date order.
                                    TempNewActionMsgEntry.Quantity += ActionMessageEntry.Quantity;
                                    TempNewActionMsgEntry.Modify();
                                end else begin
                                    TempNewActionMsgEntry := ActionMessageEntry;
                                    TempNewActionMsgEntry."Entry No." := TrkgReservEntry."Shipment Date" - 19000101D;
                                    TempNewActionMsgEntry."New Date" := TrkgReservEntry."Shipment Date";
                                    TempNewActionMsgEntry.Insert();
                                end;
                            until ActionMessageEntry.Next() = 0;

                            TempNewActionMsgEntry.Find('-');
                            repeat
                                TempActionMsgEntry := TempNewActionMsgEntry;
                                NextEntryNo := NextEntryNo + 1;
                                TempActionMsgEntry."Entry No." := NextEntryNo;
                                TempActionMsgEntry.Insert();
                            until TempNewActionMsgEntry.Next() = 0;
                        end else
                            if ActionMessageEntry.Find('+') then
                                UpdateActionMessageList(
                                    ActionMessageEntry."Source Type", ActionMessageEntry."Source Subtype",
                                    ActionMessageEntry."Source ID", ActionMessageEntry."Source Batch Name",
                                    ActionMessageEntry."Source Prod. Order Line", ActionMessageEntry."Source Ref. No.",
                                    ActionMessageEntry."Location Code", ActionMessageEntry."Bin Code",
                                    ActionMessageEntry."Variant Code", ActionMessageEntry."Item No.", 0D);
                        ActionMessageEntry.ClearSourceFilter();
                        ActionMessageEntry.SetRange("Location Code");
                        ActionMessageEntry.SetRange("Bin Code");
                        ActionMessageEntry.SetRange("Variant Code");
                    until ActionMessageEntry.Next() = 0;
            end;

            trigger OnPostDataItem()
            begin
                if TempItemInOtherWksh.FindFirst() then begin
                    Window.Close();
                    if Confirm(Text002) then
                        PAGE.RunModal(0, TempItemInOtherWksh);
                    if not Confirm(Text005) then
                        Error(Text006);
                    Window.Open(
                      '#1##########################\\' +
                      Text000);
                end;

                Window.Update(1, Text007);

                TempActionMsgEntry.Reset();
                PlanningLinesInserted := false;
                if not TempActionMsgEntry.Find('-') then
                    Error(Text008);

                repeat
                    GetActionMessages(TempActionMsgEntry);
                until TempActionMsgEntry.Next() = 0;

                if not PlanningLinesInserted then
                    Error(Text008);

                // Dynamic tracking is run for the handled Planning Lines:
                if TempReqLineList.Find('-') then
                    repeat
                        ReservMgt.SetReservSource(TempReqLineList);
                        ReservMgt.AutoTrack(TempReqLineList."Net Quantity (Base)");
                    until TempReqLineList.Next() = 0;

                // Dynamic tracking is run for the handled Planning Components:
                if TempPlanningCompList.Find('-') then
                    repeat
                        ReservMgt.SetReservSource(TempPlanningCompList);
                        ReservMgt.AutoTrack(TempPlanningCompList."Net Quantity (Base)");
                    until TempPlanningCompList.Next() = 0;
            end;

            trigger OnPreDataItem()
            begin
                CopyFilter("Variant Filter", ActionMessageEntry."Variant Code");
                CopyFilter("Location Filter", ActionMessageEntry."Location Code");
                CopyFilter("Bin Filter", ActionMessageEntry."Bin Code");

                ReqLineExtern.SetCurrentKey(Type, "No.", "Variant Code", "Location Code");
                ReqLineExtern.SetRange(Type, ReqLineExtern.Type::Item);
                CopyFilter("Variant Filter", ReqLineExtern."Variant Code");
                CopyFilter("Location Filter", ReqLineExtern."Location Code");

                ActionMessageEntry.SetCurrentKey("Source Type", "Source Subtype", "Source ID", "Source Batch Name",
                  "Source Prod. Order Line", "Source Ref. No.");
                ActionMessageEntry2.SetCurrentKey("Reservation Entry");

                TempItemInOtherWksh.DeleteAll();
                TempActionMsgEntry.DeleteAll();
                TempReqLineList.DeleteAll();
                TempPlanningCompList.DeleteAll();

                InventorySetup.Get();
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        Window.Open(
          '#1##########################\\' +
          Text000);
    end;

    var
        ReqLineExtern: Record "Requisition Line";
        TrkgReservEntry: Record "Reservation Entry";
        TempItemInOtherWksh: Record Item temporary;
        TempActionMsgEntry: Record "Action Message Entry" temporary;
        TempNewActionMsgEntry: Record "Action Message Entry" temporary;
        ActionMessageEntry: Record "Action Message Entry";
        ActionMessageEntry2: Record "Action Message Entry";
        InventorySetup: Record "Inventory Setup";
        TempPlanningCompList: Record "Planning Component" temporary;
        TempReqLineList: Record "Requisition Line" temporary;
        SKU: Record "Stockkeeping Unit";
        InvtProfileOffsetting: Codeunit "Inventory Profile Offsetting";
        ReservMgt: Codeunit "Reservation Management";
        GetPlanningParameters: Codeunit "Planning-Get Parameters";
        UOMMgt: Codeunit "Unit of Measure Management";
        Window: Dialog;
        NextEntryNo: Integer;
        CurrTemplateName: Code[10];
        CurrWorksheetName: Code[10];
        PlanningLinesInserted: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Item No.  #2##################';
#pragma warning restore AA0470
        Text001: Label 'Building action message list...';
        Text002: Label 'Some items within the filter already exist on the planning lines.\Action messages that are related to these items will not be processed.\\Do you want to see a list of the unprocessed items?';
        Text005: Label 'Do you want to continue?';
        Text006: Label 'The process has been canceled.';
        Text007: Label 'Processing action messages...';
        Text008: Label 'No action messages exist.';
        Text009: Label 'GetActionMessages: Illegal Action Message relation.';
#pragma warning restore AA0074

    procedure SetTemplAndWorksheet(TemplateName: Code[10]; WorksheetName: Code[10])
    begin
        CurrTemplateName := TemplateName;
        CurrWorksheetName := WorksheetName;
    end;

#if not CLEAN27
    [Obsolete('Replaced by UpdateActionMessageList due to extending ForBin to Code20', '27.0')]
    procedure UpdateActionMsgList(ForType: Integer; ForSubtype: Integer; ForID: Code[20]; ForBatchName: Code[10]; ForProdOrderLine: Integer; ForRefNo: Integer; ForLocation: Code[10]; ForBin: Code[10]; ForVariant: Code[10]; ForItem: Code[20]; OrderDate: Date)
    begin
        UpdateActionMessageList(ForType, ForSubtype, ForID, ForBatchName, ForProdOrderLine, ForRefNo, ForLocation, ForBin, ForVariant, ForItem, OrderDate);
    end;
#endif

    procedure UpdateActionMessageList(ForType: Integer; ForSubtype: Integer; ForID: Code[20]; ForBatchName: Code[10]; ForProdOrderLine: Integer; ForRefNo: Integer; ForLocation: Code[10]; ForBin: Code[20]; ForVariant: Code[10]; ForItem: Code[20]; OrderDate: Date)
    begin
        TempActionMsgEntry.SetSourceFilter(ForType, ForSubtype, ForID, ForRefNo, false);
        TempActionMsgEntry.SetSourceFilter(ForBatchName, ForProdOrderLine);
        TempActionMsgEntry.SetRange(TempActionMsgEntry."Location Code", ForLocation);
        TempActionMsgEntry.SetRange(TempActionMsgEntry."Bin Code", ForBin);
        TempActionMsgEntry.SetRange(TempActionMsgEntry."Variant Code", ForVariant);
        TempActionMsgEntry.SetRange(TempActionMsgEntry."Item No.", ForItem);
        TempActionMsgEntry.SetRange(TempActionMsgEntry."New Date", OrderDate);
        if TempActionMsgEntry.Find('-') then
            exit;

        TempActionMsgEntry.SetSource(ForType, ForSubtype, ForID, ForRefNo, ForBatchName, ForProdOrderLine);
        TempActionMsgEntry."Location Code" := ForLocation;
        TempActionMsgEntry."Bin Code" := ForBin;
        TempActionMsgEntry."Variant Code" := ForVariant;
        TempActionMsgEntry."Item No." := ForItem;
        TempActionMsgEntry."New Date" := OrderDate;
        NextEntryNo := NextEntryNo + 1;
        TempActionMsgEntry."Entry No." := NextEntryNo;
        TempActionMsgEntry.Insert();
    end;

    procedure GetActionMessages(ActionMsgEntry: Record "Action Message Entry")
    var
        ReqLine: Record "Requisition Line";
        InsertNew: Boolean;
    begin
        if ActionMsgEntry."Source ID" = '' then // Not related to existing order.
            ActionMessageEntry := ActionMsgEntry
        else begin
            ActionMessageEntry.SetSourceFilterFromActionEntry(ActionMsgEntry);
            ActionMessageEntry.SetRange("Location Code", ActionMsgEntry."Location Code");
            ActionMessageEntry.SetRange("Bin Code", ActionMsgEntry."Bin Code");
            ActionMessageEntry.SetRange("Variant Code", ActionMsgEntry."Variant Code");
            ActionMessageEntry.SetRange("Item No.", ActionMsgEntry."Item No.");
            if not ActionMessageEntry.Find('-') then
                exit;
        end;

        GetPlanningParameters.AtSKU(SKU, ActionMessageEntry."Item No.", ActionMessageEntry."Variant Code", ActionMessageEntry."Location Code");
        InsertNew := false;
        ReqLine."Worksheet Template Name" := CurrTemplateName;
        ReqLine."Journal Batch Name" := CurrWorksheetName;
        ReqLine."Line No." += 10000;
        while not ReqLine.Insert() do
            ReqLine."Line No." += 10000;

        InsertNew := InitReqFromSource(ActionMsgEntry, ReqLine);

        Window.Update(2, ReqLine."No.");

        if ActionMsgEntry."Source ID" = '' then begin
            ActionMessageEntry.Quantity := ActionMsgEntry.Quantity;
            ActionMessageEntry.Type := ActionMessageEntry.Type::New;
            ReqLine."Due Date" := ActionMsgEntry."New Date";
            ReqLine."Ending Date" := ReqLine."Due Date" - 1;
        end else
            ActionMessageEntry.SumUp(ActionMessageEntry);

        if ActionMessageEntry.Quantity < 0 then
            if SKU."Lot Size" > 0 then
                if InventorySetup."Default Dampener %" > 0 then
                    if InventorySetup."Default Dampener %" * SKU."Lot Size" / 100 >= Abs(ActionMessageEntry.Quantity) then
                        ActionMessageEntry.Quantity := 0;
        if (ActionMessageEntry.Quantity = 0) and (ActionMessageEntry."New Date" = 0D) then
            exit;

        ReqLine."Original Quantity" := ReqLine.Quantity;
        ReqLine."Quantity (Base)" += ActionMessageEntry.Quantity;
        ReqLine.Quantity := Round(ReqLine."Quantity (Base)" / ReqLine."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
        ReqLine."Remaining Quantity" := ReqLine.Quantity - ReqLine."Finished Quantity";
        ReqLine."Remaining Qty. (Base)" :=
          Round(ReqLine."Remaining Quantity" / ReqLine."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
        if InsertNew then
            ActionMessageEntry.Type := ActionMessageEntry.Type::New;
        if ActionMessageEntry."New Date" <> 0D then begin
            if ActionMessageEntry.Type <> ActionMessageEntry.Type::New then
                ReqLine."Original Due Date" := ReqLine."Due Date";
            ReqLine."Due Date" := ActionMessageEntry."New Date";
            ReqLine."Starting Date" := 0D;
            if ActionMessageEntry.BoundToComponent() then begin
                ReqLine."Ending Date" := ActionMessageEntry.ComponentDueDate();
                ReqLine."Ending Time" := ActionMessageEntry.ComponentDueTime();
            end else
                ReqLine."Ending Date" := 0D;
        end;
        if ReqLine.Quantity = 0 then
            ReqLine."Action Message" := ReqLine."Action Message"::Cancel
        else
            ReqLine."Action Message" := ActionMessageEntry.Type;
        ReqLine."Planning Line Origin" := ReqLine."Planning Line Origin"::"Action Message";
        ReqLine."Accept Action Message" := true;
        ReqLine.Modify();
        if ReqLine."Starting Date" = 0D then
            ReqLine."Starting Date" := ReqLine."Due Date";
        if ReqLine."Ending Date" = 0D then
            ReqLine."Ending Date" := ReqLine."Due Date" - 1;
        ReqLine.BlockDynamicTracking(true);
        GetRoutingAndComponents(ReqLine);
        if ReqLine."Original Due Date" <> 0D then
            if not (ReqLine."Action Message" in [ReqLine."Action Message"::Reschedule,
                                                 ReqLine."Action Message"::"Resched. & Chg. Qty."])
            then
                ReqLine."Original Due Date" := 0D;
        if ReqLine."Original Quantity" = ReqLine.Quantity then
            if ReqLine."Action Message" = ReqLine."Action Message"::"Resched. & Chg. Qty." then
                ReqLine."Action Message" := ReqLine."Action Message"::Reschedule;
        ReqLine.Validate(Quantity);
        if ReqLine."Action Message" = ReqLine."Action Message"::Reschedule then
            ReqLine."Original Quantity" := 0;
        ReqLine.Modify();
        Clear(ReqLineExtern);
        // Retrieve temporary list of Planning Components handled:
        InvtProfileOffsetting.GetPlanningCompList(TempPlanningCompList);
        // Save inserted Planning Line in temporary list:
        TempReqLineList := ReqLine;
        TempReqLineList.Insert();

        PlanningLinesInserted := true;
    end;

    local procedure InitReqFromSource(ActionMsgEntry: Record "Action Message Entry"; var ReqLine: Record "Requisition Line"): Boolean
    var
        PurchOrderLine: Record "Purchase Line";
        TransLine: Record "Transfer Line";
        IsHandled: Boolean;
        ShouldExit: Boolean;
    begin
        case ActionMsgEntry."Source Type" of
            Database::"Purchase Line":
                if PurchOrderLine.Get(ActionMsgEntry."Source Subtype", ActionMsgEntry."Source ID", ActionMsgEntry."Source Ref. No.") then begin
                    ReqLine.GetPurchOrderLine(PurchOrderLine);
                    exit(false);
                end;
            Database::"Transfer Line":
                if TransLine.Get(ActionMsgEntry."Source ID", ActionMsgEntry."Source Ref. No.") then begin
                    ReqLine.GetTransLine(TransLine);
                    exit(false);
                end;
            else begin
                IsHandled := false;
                OnInitReqFromSourceBySource(ReqLine, ActionMsgEntry, ShouldExit, IsHandled);
                if ShouldExit then
                    exit(false);
                if not IsHandled then
                    Error(Text009)
            end;
        end;
        ReqLine.TransferFromActionMessage(ActionMsgEntry);
        exit(true);
    end;

    local procedure GetRoutingAndComponents(var ReqLine: Record "Requisition Line")
    var
        Direction: Option Forward,Backward;
    begin
        InvtProfileOffsetting.GetRouting(ReqLine);
        InvtProfileOffsetting.GetComponents(ReqLine);
        InvtProfileOffsetting.Recalculate(ReqLine, Direction::Backward, true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitReqFromSourceBySource(var ReqLine: Record "Requisition Line"; ActionMessageEntry: Record "Action Message Entry"; var ShouldExit: Boolean; var IsHandled: Boolean)
    begin
    end;
}

