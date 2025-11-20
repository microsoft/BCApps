// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Posting;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Purchases.Document;
using Microsoft.Utilities;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Worksheet;
using System.Environment.Configuration;
using System.Telemetry;
using System.Utilities;

codeunit 5407 "Prod. Order Status Management"
{
    Permissions = TableData "Source Code Setup" = r,
                  TableData "Production Order" = rimd,
                  TableData "Prod. Order Capacity Need" = rid,
                  TableData "Inventory Adjmt. Entry (Order)" = rim;
    TableNo = "Production Order";

    trigger OnRun()
    var
        ChangeStatusForm: Page "Change Status on Prod. Order";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnRun(ChangeStatusForm, Rec, IsHandled, NewStatus, NewPostingDate, NewUpdateUnitCost);
        if IsHandled then
            exit;

        ChangeStatusForm.Set(Rec);
        if ChangeStatusForm.RunModal() = ACTION::Yes then begin
            OnRunOnAfterChangeStatusFormRun(Rec, ChangeStatusForm);
            ChangeStatusForm.ReturnPostingInfo(NewStatus, NewPostingDate, NewUpdateUnitCost, FinishOrderWithoutOutput);
            ChangeProdOrderStatus(Rec, NewStatus, NewPostingDate, NewUpdateUnitCost);
            Commit();
            ShowStatusMessage(Rec);
        end;
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%2 %3  with status %1 has been changed to %5 %6 with status %4.';
#pragma warning restore AA0470
        Text002: Label 'Posting Automatic consumption...\\';
#pragma warning disable AA0470
        Text003: Label 'Posting lines         #1###### @2@@@@@@@@@@@@@';
#pragma warning restore AA0470
        Text005: Label 'The update has been interrupted to respect the warning.';
#pragma warning disable AA0470
        ToProdOrder: Record "Production Order";
        SourceCodeSetup: Record "Source Code Setup";
        Item: Record Item;
        InventorySetup: Record "Inventory Setup";
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimMgt: Codeunit DimensionManagement;
        MfgCostCalcMgt: Codeunit "Mfg. Cost Calculation Mgt.";
        ProdOrderLineReserve: Codeunit "Prod. Order Line-Reserve";
        ProdOrderCompReserve: Codeunit "Prod. Order Comp.-Reserve";
        ReservMgt: Codeunit "Reservation Management";
        CalendarMgt: Codeunit "Shop Calendar Management";
        UpdateProdOrderCost: Codeunit "Update Prod. Order Cost";
        ACYMgt: Codeunit "Additional-Currency Management";
        WhseProdRelease: Codeunit "Whse.-Production Release";
        WhseOutputProdRelease: Codeunit "Whse.-Output Prod. Release";
        UOMMgt: Codeunit "Unit of Measure Management";
        MfgCreatePutaway: Codeunit "Mfg. Create Put-away";
        NewStatus: Enum "Production Order Status";
        NewPostingDate: Date;
        NewUpdateUnitCost: Boolean;
        SourceCodeSetupRead: Boolean;
        FinishOrderWithoutOutput: Boolean;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text008: Label '%1 %2 cannot be finished as the associated subcontract order %3 has not been fully delivered.';
        Text009: Label 'You cannot finish line %1 on %2 %3. It has consumption or capacity posted with no output.';
        Text010: Label 'You must specify a %1 in %2 %3 %4.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        ProdOrderCompRemainToPickErr: Label 'You cannot finish production order no. %1 because there is an outstanding pick for one or more components.', Comment = '%1: Production Order No.';
        ChangingStatusInfoLbl: Label 'Changing status to %1...\\', Comment = '%1 - New Status';
        ProcessingProgressTxt: Label 'Prod. Order #1###### @2@@@@@@@@@@@@@', Comment = '%1 - Production Order No.; %2 - Progress Percentage';
        ConfirmationLbl: Label '%1 production orders will have their status changed from %2 to %3.', Comment = '%1 - Number of Prod. Orders selected; %2 - Current status; %3 - New status';
        CanReOpenFinishedProdOrderQst: Label 'Do you want to reopen the production order %1 ?', Comment = '%1 - Production Order No.';
        OpenReleasedProdOrderQst: Label 'The production order is reopened and moved to the %1 Production Order with status Released.\\Do you want to open the production order?', Comment = '%1 = Production Order No.';
        ReopenFinishedProductionOrderFeatureTelemetryNameLbl: Label 'Reopen Finished Production Order', Locked = true;
        ReopenedProductionOrderLbl: Label 'The production order is reopened and moved to the %1 Production Order with status Released.', Comment = '%1 = Production Order No.';
        ProductionOrderHasAlreadyBeenReopenedErr: Label 'This production order has already been reopened before. This can only be done once.';
        ProductionOrderCannotBeReopenedErr: Label 'This production order cannot be reopened because one or more production order lines have no posted output.';
        FinishOrderWithOutputWarningQst: Label '%1 %2 has not been finished:\\  * Some output is still missing.\\ Do you still want to finish the order?', Comment = '%1 - Production Order Table Name ; %2 - Production Order No.';
        FinishOrderWithConsumptionWarningQst: Label '%1 %2 has not been finished:\\  * Some consumption is still missing.\\ Do you still want to finish the order?', Comment = '%1 - Production Order Table Name ; %2 - Production Order No.';
        FinishOrderWithOutputAndConsumptionWarningQst: Label '%1 %2 has not been finished:\\  * Some output is still missing.\  * Some consumption is still missing.\\ Do you still want to finish the order?', Comment = '%1 - Production Order Table Name ; %2 - Production Order No.';

    procedure ChangeProdOrderStatus(ProdOrder: Record "Production Order"; NewStatus: Enum "Production Order Status"; NewPostingDate: Date; NewUpdateUnitCost: Boolean)
    var
        SuppressCommit: Boolean;
        IsHandled: Boolean;
    begin
        SetPostingInfo(NewStatus, NewPostingDate, NewUpdateUnitCost);
        IsHandled := false;
        OnBeforeChangeStatusOnProdOrder(ProdOrder, NewStatus.AsInteger(), IsHandled, NewPostingDate, NewUpdateUnitCost);
        if IsHandled then
            exit;
        if (NewStatus = Enum::"Production Order Status"::Released) and (ProdOrder."Source Type" = ProdOrder."Source Type"::Item) then
            Item.CheckItemAndVariantForProdBlocked(ProdOrder."Source No.", '', Enum::"Item Production Blocked"::Output);
        if NewStatus = NewStatus::Finished then begin
            if not IsVariantCodeMandatory(ProdOrder) then begin
                CheckBeforeFinishProdOrder(ProdOrder);
                FlushProdOrder(ProdOrder, NewStatus, NewPostingDate);
                IsHandled := false;
                OnChangeProdOrderStatusOnBeforeDeleteDocReservation(ProdOrder, IsHandled);
                if not IsHandled then
                    ReservMgt.DeleteDocumentReservation(Database::"Prod. Order Line", ProdOrder.Status.AsInteger(), ProdOrder."No.", false);
                ErrorIfUnableToClearWIP(ProdOrder);
                TransProdOrder(ProdOrder);

                MakeMultiLevelAdjmt(ProdOrder);
                AdjustWIPForProduction(ProdOrder);

                WhseProdRelease.FinishedDelete(ProdOrder);
                WhseOutputProdRelease.FinishedDelete(ProdOrder);
            end;
        end else begin
            OnChangeProdOrderStatusOnBeforeTransProdOrder(ProdOrder, NewStatus);
            TransProdOrder(ProdOrder);
            FlushProdOrder(ProdOrder, NewStatus, NewPostingDate);
            WhseProdRelease.Release(ProdOrder);
        end;
        SuppressCommit := false;
        OnAfterChangeStatusOnProdOrder(ProdOrder, ToProdOrder, NewStatus, NewPostingDate, NewUpdateUnitCost, SuppressCommit);

        if not SuppressCommit then
            Commit();
    end;

    procedure ReopenFinishedProdOrder(var ProdOrder: Record "Production Order")
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        FeatureTelemetry.LogUptake('0000OHX', GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::Used);
        if not CanReopenFinishedProdOrder(ProdOrder) then
            Error('');

        ProcessProdOrderForReopen(ProdOrder);
        ShowReleasedProdOrderDocument(ProdOrder);
        FeatureTelemetry.LogUsage('0000OHY', GetFeatureTelemetryName(), StrSubstNo(ReopenedProductionOrderLbl, ProdOrder."No."));
    end;

    local procedure CanReopenFinishedProdOrder(ProdOrder: Record "Production Order"): Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        exit(ConfirmManagement.GetResponseOrDefault(StrSubstNo(CanReOpenFinishedProdOrderQst, ProdOrder."No."), true));
    end;

    local procedure ProcessProdOrderForReopen(var ProdOrder: Record "Production Order")
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ValidateProdOrderHeaderForReopen(ProdOrder);
        TransferReopenProdOrder(ProdOrder);

        ProdOrderLine.SetRange(Status, ProdOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrder."No.");
        if ProdOrderLine.FindSet() then
            repeat
                ProcessProdOrderLineForReopen(ProdOrderLine);
            until ProdOrderLine.Next() = 0;

        TransferRelatedTablesToReleasedProdOrder(ProdOrder);
        ProdOrder.Delete();
    end;

    local procedure TransferRelatedTablesToReleasedProdOrder(ProdOrder: Record "Production Order")
    begin
        TransferReopenProdOrderRtngLine(ProdOrder);
        TransReopenProdOrderRtngTool(ProdOrder);
        TransReopenProdOrderRtngPersnl(ProdOrder);
        TransReopenProdOrdRtngQltyMeas(ProdOrder);
        TransReopenProdOrderCmtLine(ProdOrder);
        TransReopenProdOrderRtngCmtLn(ProdOrder);
        TransReopenProdOrderBOMCmtLine(ProdOrder);

        OnAfterTransferRelatedTablesToReleasedProdOrder(ProdOrder);
    end;

    local procedure ShowReleasedProdOrderDocument(var ProdOrder: Record "Production Order")
    var
        NewProductionOrder: Record "Production Order";
    begin
        if not Confirm(StrSubstNo(OpenReleasedProdOrderQst, ProdOrder."No.")) then
            exit;

        NewProductionOrder.Get(NewProductionOrder.Status::Released, ProdOrder."No.");
        Page.Run(Page::"Released Production Order", NewProductionOrder);
    end;

    local procedure ValidateProdOrderHeaderForReopen(ProdOrder: Record "Production Order")
    begin
        ProdOrder.TestField(Status, ProdOrder.Status::Finished);
        if ProdOrder.Reopened then
            Error(ProductionOrderHasAlreadyBeenReopenedErr);

        if CheckIfFinishedQtyIsZero(ProdOrder) then
            Error(ProductionOrderCannotBeReopenedErr);
    end;

    local procedure ProcessProdOrderLineForReopen(ProdOrderLine: Record "Prod. Order Line")
    var
        UpdateProdOrderLine: Record "Prod. Order Line";
    begin
        ValidateProdOrderLineForReopen(ProdOrderLine);
        TransferReopenProdOrderLine(ProdOrderLine);
        TransReopenProdOrderComp(ProdOrderLine);
        UpdateSourceSubtypeForPutAwayDocumentWhenStatusIsChanged(ProdOrderLine, ProdOrderLine.Status::Released);
        OnProcessProdOrderLineForReopenOnBeforeDeleteUpdateProdOrderLine(ProdOrderLine);
        UpdateProdOrderLine.Get(ProdOrderLine.Status, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.");
        UpdateProdOrderLine.Delete();
    end;

    local procedure TransferReopenProdOrder(FromProdOrder: Record "Production Order")
    var
        ProductionOrder: Record "Production Order";
    begin
        ProductionOrder.Init();
        ProductionOrder := FromProdOrder;
        ProductionOrder.Status := ProductionOrder.Status::Released;
        ProductionOrder."Reopened" := true;
        ProductionOrder.Insert();

        OnAfterTransferReopenProdOrder(ProductionOrder, FromProdOrder);
    end;

    local procedure TransferReopenProdOrderLine(FromProdOrderLine: Record "Prod. Order Line")
    var
        Item: Record Item;
        ProductionOrderLine: Record "Prod. Order Line";
        InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
    begin
        ProductionOrderLine.Init();
        ProductionOrderLine := FromProdOrderLine;
        ProductionOrderLine.Status := ProductionOrderLine.Status::Released;
        ProductionOrderLine.Insert();

        InvtAdjmtEntryOrder.Get(InvtAdjmtEntryOrder."Order Type"::Production, FromProdOrderLine."Prod. Order No.", FromProdOrderLine."Line No.");
        InvtAdjmtEntryOrder."Routing No." := ProductionOrderLine."Routing No.";
        InvtAdjmtEntryOrder."Cost is Adjusted" := false;
        InvtAdjmtEntryOrder."Is Finished" := false;
        InvtAdjmtEntryOrder.Modify();

        Item.Get(ProductionOrderLine."Item No.");
        Item."Cost is Adjusted" := false;
        Item.Modify();

        OnAfterTransferReopenProdOrderLine(ProductionOrderLine, FromProdOrderLine);
    end;

    local procedure TransReopenProdOrderComp(FromProdOrderLine: Record "Prod. Order Line")
    var
        FromProdOrderComponent: Record "Prod. Order Component";
        NewProdOrderComponent: Record "Prod. Order Component";
    begin
        FromProdOrderComponent.SetRange(Status, FromProdOrderLine.Status);
        FromProdOrderComponent.SetRange("Prod. Order No.", FromProdOrderLine."Prod. Order No.");
        FromProdOrderComponent.SetRange("Prod. Order Line No.", FromProdOrderLine."Line No.");
        if FromProdOrderComponent.FindSet() then begin
            repeat
                NewProdOrderComponent.Init();
                NewProdOrderComponent := FromProdOrderComponent;
                NewProdOrderComponent.Status := NewProdOrderComponent.Status::Released;
                NewProdOrderComponent.Insert();
            until FromProdOrderComponent.Next() = 0;
            FromProdOrderComponent.DeleteAll();
        end;
    end;

    local procedure TransferReopenProdOrderRtngLine(FromProdOrder: Record "Production Order")
    var
        FromProdOrderRtngLine: Record "Prod. Order Routing Line";
        ToProdOrderRtngLine: Record "Prod. Order Routing Line";
    begin
        FromProdOrderRtngLine.SetRange(Status, FromProdOrder.Status);
        FromProdOrderRtngLine.SetRange("Prod. Order No.", FromProdOrder."No.");
        if FromProdOrderRtngLine.FindSet() then begin
            repeat
                ToProdOrderRtngLine.Init();
                ToProdOrderRtngLine := FromProdOrderRtngLine;
                ToProdOrderRtngLine.Status := ToProdOrderRtngLine.Status::Released;
                ToProdOrderRtngLine."Routing Status" := ToProdOrderRtngLine."Routing Status"::"In Progress";
                ToProdOrderRtngLine.Insert();
            until FromProdOrderRtngLine.Next() = 0;
            FromProdOrderRtngLine.DeleteAll();
        end;
    end;

    local procedure TransReopenProdOrderRtngPersnl(FromProdOrder: Record "Production Order")
    var
        FromProdOrderRtngPersonnel: Record "Prod. Order Routing Personnel";
        ToProdOrderRtngPersonnel: Record "Prod. Order Routing Personnel";
    begin
        FromProdOrderRtngPersonnel.SetRange(Status, FromProdOrder.Status);
        FromProdOrderRtngPersonnel.SetRange("Prod. Order No.", FromProdOrder."No.");
        if FromProdOrderRtngPersonnel.FindSet() then begin
            repeat
                ToProdOrderRtngPersonnel.Init();
                ToProdOrderRtngPersonnel := FromProdOrderRtngPersonnel;
                ToProdOrderRtngPersonnel.Status := ToProdOrderRtngPersonnel.Status::Released;
                ToProdOrderRtngPersonnel.Insert();
            until FromProdOrderRtngPersonnel.Next() = 0;
            FromProdOrderRtngPersonnel.DeleteAll();
        end;
    end;

    local procedure TransReopenProdOrdRtngQltyMeas(FromProdOrder: Record "Production Order")
    var
        FromProdOrderRtngQltyMeas: Record "Prod. Order Rtng Qlty Meas.";
        ToProdOrderRtngQltyMeas: Record "Prod. Order Rtng Qlty Meas.";
    begin
        FromProdOrderRtngQltyMeas.SetRange(Status, FromProdOrder.Status);
        FromProdOrderRtngQltyMeas.SetRange("Prod. Order No.", FromProdOrder."No.");
        if FromProdOrderRtngQltyMeas.FindSet() then begin
            repeat
                ToProdOrderRtngQltyMeas := FromProdOrderRtngQltyMeas;
                ToProdOrderRtngQltyMeas.Status := ToProdOrderRtngQltyMeas.Status::Released;
                ToProdOrderRtngQltyMeas.Insert();
            until FromProdOrderRtngQltyMeas.Next() = 0;
            FromProdOrderRtngQltyMeas.DeleteAll();
        end;
    end;

    local procedure TransReopenProdOrderCmtLine(FromProdOrder: Record "Production Order")
    var
        FromProdOrderCommentLine: Record "Prod. Order Comment Line";
        ToProdOrderCommentLine: Record "Prod. Order Comment Line";
    begin
        FromProdOrderCommentLine.SetRange(Status, FromProdOrder.Status);
        FromProdOrderCommentLine.SetRange("Prod. Order No.", FromProdOrder."No.");
        if FromProdOrderCommentLine.FindSet() then begin
            repeat
                ToProdOrderCommentLine := FromProdOrderCommentLine;
                ToProdOrderCommentLine.Status := ToProdOrderCommentLine.Status::Released;
                ToProdOrderCommentLine.Insert();
            until FromProdOrderCommentLine.Next() = 0;
            FromProdOrderCommentLine.DeleteAll();
        end;
        TransferLinks(FromProdOrder, ToProdOrder);
    end;

    local procedure TransReopenProdOrderRtngCmtLn(FromProdOrder: Record "Production Order")
    var
        FromProdOrderRtngComment: Record "Prod. Order Rtng Comment Line";
        ToProdOrderRtngComment: Record "Prod. Order Rtng Comment Line";
    begin
        FromProdOrderRtngComment.SetRange(Status, FromProdOrder.Status);
        FromProdOrderRtngComment.SetRange("Prod. Order No.", FromProdOrder."No.");
        if FromProdOrderRtngComment.FindSet() then begin
            repeat
                ToProdOrderRtngComment := FromProdOrderRtngComment;
                ToProdOrderRtngComment.Status := ToProdOrderRtngComment.Status::Released;
                ToProdOrderRtngComment.Insert();
            until FromProdOrderRtngComment.Next() = 0;
            FromProdOrderRtngComment.DeleteAll();
        end;
    end;

    local procedure TransReopenProdOrderBOMCmtLine(FromProdOrder: Record "Production Order")
    var
        FromProdOrderBOMComment: Record "Prod. Order Comp. Cmt Line";
        ToProdOrderBOMComment: Record "Prod. Order Comp. Cmt Line";
    begin
        FromProdOrderBOMComment.SetRange(Status, FromProdOrder.Status);
        FromProdOrderBOMComment.SetRange("Prod. Order No.", FromProdOrder."No.");
        if FromProdOrderBOMComment.FindSet() then begin
            repeat
                ToProdOrderBOMComment := FromProdOrderBOMComment;
                ToProdOrderBOMComment.Status := ToProdOrderBOMComment.Status::Released;
                ToProdOrderBOMComment.Insert();
            until FromProdOrderBOMComment.Next() = 0;
            FromProdOrderBOMComment.DeleteAll();
        end;
    end;

    local procedure TransReopenProdOrderRtngTool(FromProdOrder: Record "Production Order")
    var
        FromProdOrderRtngTool: Record "Prod. Order Routing Tool";
        ToProdOrderRoutTool: Record "Prod. Order Routing Tool";
    begin
        FromProdOrderRtngTool.SetRange(Status, FromProdOrder.Status);
        FromProdOrderRtngTool.SetRange("Prod. Order No.", FromProdOrder."No.");
        FromProdOrderRtngTool.LockTable();
        if FromProdOrderRtngTool.FindSet() then begin
            repeat
                ToProdOrderRoutTool := FromProdOrderRtngTool;
                ToProdOrderRoutTool.Status := ToProdOrderRoutTool.Status::Released;
                ToProdOrderRoutTool.Insert();
            until FromProdOrderRtngTool.Next() = 0;
            FromProdOrderRtngTool.DeleteAll();
        end;
    end;

    local procedure ValidateProdOrderLineForReopen(ProdOrderLine: Record "Prod. Order Line")
    begin
        ProdOrderLine.TestField(Status, ProdOrderLine.Status::Finished);
    end;

    local procedure GetFeatureTelemetryName(): Text
    begin
        exit(ReopenFinishedProductionOrderFeatureTelemetryNameLbl);
    end;

    procedure SetFinishOrderWithoutOutput(NewFinishOrderWithoutOutput: Boolean)
    begin
        FinishOrderWithoutOutput := NewFinishOrderWithoutOutput;
    end;

    local procedure AdjustWIPForProduction(ProductionOrder: Record "Production Order")
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetLoadFields("Order Type", "Order No.", "Order Line No.", "Cost Posted to G/L", "Cost Posted to G/L (ACY)", "Expected Cost");
        ValueEntry.SetRange("Order Type", ValueEntry."Order Type"::Production);
        ValueEntry.SetRange("Order No.", ProductionOrder."No.");
        ValueEntry.SetFilter("Cost Posted to G/L", '<>%1', 0);
        ValueEntry.SetRange("Expected Cost", false);
        if ValueEntry.FindSet() then
            repeat
                PostInvtBuffer(ValueEntry);
            until ValueEntry.Next() = 0;
    end;

    local procedure PostInvtBuffer(var ValueEntry: Record "Value Entry")
    var
        InventoryPostingToGL: Codeunit "Inventory Posting To G/L";
    begin
        InventoryPostingToGL.SetRunOnlyCheck(true, false, false);
        if not InventoryPostingToGL.AdjustPostedWIPForProduction(ValueEntry) then
            exit;

        InventorySetup.GetRecordOnce();
        GeneralLedgerSetup.GetRecordOnce();
        if GeneralLedgerSetup."Journal Templ. Name Mandatory" then
            InventoryPostingToGL.SetGenJnlBatch(InventorySetup."Invt. Cost Jnl. Template Name", InventorySetup."Invt. Cost Jnl. Batch Name");

        if NewPostingDate <> 0D then
            ValueEntry."Posting Date" := NewPostingDate;
        InventoryPostingToGL.PostInvtPostBufPerEntry(ValueEntry);
    end;

    local procedure MakeMultiLevelAdjmt(ProdOrder: Record "Production Order")
    var
        InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        ItemLedgerEntry: Record "Item Ledger Entry";
        InvtAdjmtHandler: Codeunit "Inventory Adjustment Handler";
        ItemsToAdjust: List of [Code[20]];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeMakeMultiLevelAdjmt(ProdOrder, IsHandled);
        if IsHandled then
            exit;

        ItemLedgerEntry.ReadIsolation := IsolationLevel::ReadUncommitted;
        ItemLedgerEntry.SetCurrentKey("Order Type", "Order No.");
        ItemLedgerEntry.SetRange("Order Type", ItemLedgerEntry."Order Type"::Production);
        ItemLedgerEntry.SetRange("Order No.", ProdOrder."No.");
        ItemLedgerEntry.SetLoadFields("Item No.");
        if ItemLedgerEntry.FindSet() then
            repeat
                if not ItemsToAdjust.Contains(ItemLedgerEntry."Item No.") then
                    ItemsToAdjust.Add(ItemLedgerEntry."Item No.");
            until ItemLedgerEntry.Next() = 0;

        InventoryAdjmtEntryOrder.SetRange("Order Type", InventoryAdjmtEntryOrder."Order Type"::Production);
        InventoryAdjmtEntryOrder.SetRange("Order No.", ProdOrder."No.");
        InvtAdjmtHandler.MakeAutomaticInventoryAdjustment(ItemsToAdjust, InventoryAdjmtEntryOrder);
    end;

    procedure TransProdOrder(var FromProdOrder: Record "Production Order")
    var
        ToProdOrderLine: Record "Prod. Order Line";
    begin
        OnBeforeTransProdOrder(FromProdOrder, NewStatus);

        ToProdOrderLine.LockTable();

        ToProdOrder := FromProdOrder;
        ToProdOrder.Status := NewStatus;

        case FromProdOrder.Status of
            FromProdOrder.Status::Simulated:
                ToProdOrder."Simulated Order No." := FromProdOrder."No.";
            FromProdOrder.Status::Planned:
                ToProdOrder."Planned Order No." := FromProdOrder."No.";
            FromProdOrder.Status::"Firm Planned":
                ToProdOrder."Firm Planned Order No." := FromProdOrder."No.";
            FromProdOrder.Status::Released:
                begin
                    ToProdOrder."Finished Date" := NewPostingDate;
                    OnTransProdOrderOnAfterStatusIsReleased(ToProdOrder, FromProdOrder);
                end;
        end;

        ToProdOrder.TestNoSeries();
        if (ToProdOrder.GetNoSeriesCode() <> FromProdOrder.GetNoSeriesCode()) and
           (ToProdOrder.Status <> ToProdOrder.Status::Finished)
        then begin
            ToProdOrder."No." := '';
            ToProdOrder."Due Date" := 0D;
        end;

        OnTransProdOrderOnBeforeToProdOrderInsert(ToProdOrder, FromProdOrder, NewPostingDate);
        ToProdOrder.Insert(true);
        ToProdOrder."Starting Time" := FromProdOrder."Starting Time";
        ToProdOrder."Starting Date" := FromProdOrder."Starting Date";
        ToProdOrder."Ending Time" := FromProdOrder."Ending Time";
        ToProdOrder."Ending Date" := FromProdOrder."Ending Date";
        ToProdOrder.UpdateDatetime();
        ToProdOrder."Due Date" := FromProdOrder."Due Date";
        ToProdOrder."Shortcut Dimension 1 Code" := FromProdOrder."Shortcut Dimension 1 Code";
        ToProdOrder."Shortcut Dimension 2 Code" := FromProdOrder."Shortcut Dimension 2 Code";
        ToProdOrder."Dimension Set ID" := FromProdOrder."Dimension Set ID";
        OnCopyFromProdOrder(ToProdOrder, FromProdOrder);
        ToProdOrder.Modify();

        TransProdOrderLine(FromProdOrder);
        TransProdOrderRtngLine(FromProdOrder);
        TransProdOrderComp(FromProdOrder);
        TransProdOrderRtngTool(FromProdOrder);
        TransProdOrderRtngPersnl(FromProdOrder);
        TransProdOrdRtngQltyMeas(FromProdOrder);
        TransProdOrderCmtLine(FromProdOrder);
        TransProdOrderRtngCmtLn(FromProdOrder);
        TransProdOrderBOMCmtLine(FromProdOrder);
        TransProdOrderCapNeed(FromProdOrder);
        OnAfterTransProdOrder(FromProdOrder, ToProdOrder);

        FromProdOrder.Get(FromProdOrder.Status, FromProdOrder."No.");
        FromProdOrder.Delete();
        FromProdOrder := ToProdOrder;
    end;

    local procedure TransProdOrderLine(FromProdOrder: Record "Production Order")
    var
        FromProdOrderLine: Record "Prod. Order Line";
        ToProdOrderLine: Record "Prod. Order Line";
        InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        NewStatusOption: Option;
        IsHandled: Boolean;
    begin
        FromProdOrderLine.SetRange(Status, FromProdOrder.Status);
        FromProdOrderLine.SetRange("Prod. Order No.", FromProdOrder."No.");
        OnTransProdOrderLineOnAfterFromProdOrderLineSetFilters(FromProdOrderLine, FromProdOrder, NewUpdateUnitCost);
        FromProdOrderLine.LockTable();
        if FromProdOrderLine.FindSet() then begin
            OnTransProdOrderLineOnAfterFromProdOrderLineFindSet(FromProdOrderLine, ToProdOrderLine, NewStatus);
            repeat
                IsHandled := false;
                OnTransProdOrderLineOnBeforeFromProdOrderLineLoop(FromProdOrderLine, ToProdOrderLine, NewStatus, IsHandled, ToProdOrder);
                if not IsHandled then begin
                    ToProdOrderLine := FromProdOrderLine;
                    ToProdOrderLine.Status := ToProdOrder.Status;
                    ToProdOrderLine."Prod. Order No." := ToProdOrder."No.";
                    InsertProdOrderLine(ToProdOrderLine, FromProdOrderLine);
                    if NewStatus = NewStatus::Finished then begin
                        if InvtAdjmtEntryOrder.Get(InvtAdjmtEntryOrder."Order Type"::Production, FromProdOrderLine."Prod. Order No.", FromProdOrderLine."Line No.") then begin
                            InvtAdjmtEntryOrder."Routing No." := ToProdOrderLine."Routing No.";
                            InvtAdjmtEntryOrder.Modify();
                        end else
                            InvtAdjmtEntryOrder.SetProdOrderLine(FromProdOrderLine);
                        if MfgCostCalcMgt.CanIncNonInvCostIntoProductionItem() then
                            GetNonInvtDirectCost(InvtAdjmtEntryOrder, InvtAdjmtEntryOrder."Direct Cost Non-Inventory", InvtAdjmtEntryOrder."Direct Cost Non-Inv. (ACY)");
                        InvtAdjmtEntryOrder."Cost is Adjusted" := false;
                        InvtAdjmtEntryOrder."Is Finished" := true;
                        OnTransProdOrderLineOnBeforeFinishedInvtAdjmtEntryOrderModify(InvtAdjmtEntryOrder, FromProdOrderLine, ToProdOrderLine, ToProdOrder);
                        InvtAdjmtEntryOrder.Modify();

                        if NewUpdateUnitCost then
                            UpdateProdOrderCost.UpdateUnitCostOnProdOrder(FromProdOrderLine, true, true);
                        ToProdOrderLine."Unit Cost (ACY)" :=
                          ACYMgt.CalcACYAmt(ToProdOrderLine."Unit Cost", NewPostingDate, true);
                        ToProdOrderLine."Cost Amount (ACY)" :=
                          ACYMgt.CalcACYAmt(ToProdOrderLine."Cost Amount", NewPostingDate, false);
                        ReservMgt.SetReservSource(FromProdOrderLine);
                        ReservMgt.DeleteReservEntries(true, 0);
                        UpdateSourceSubtypeForPutAwayDocumentWhenStatusIsChanged(FromProdOrderLine, NewStatus);
                        OnTransProdOrderLineOnAfterDeleteReservEntries(FromProdOrderLine, ToProdOrderLine, NewStatus);
                    end else begin
                        if Item.Get(FromProdOrderLine."Item No.") then
                            if (Item."Costing Method" <> Item."Costing Method"::Standard) and NewUpdateUnitCost then
                                UpdateProdOrderCost.UpdateUnitCostOnProdOrder(FromProdOrderLine, false, true);
                        ToProdOrderLine.BlockDynamicTracking(true);
                        ToProdOrderLine.Validate(Quantity);
                        OnTransProdOrderLineOnBeforeTransferPOLineToPOLine(FromProdOrderLine, ToProdOrderLine, NewStatus);
                        ProdOrderLineReserve.TransferPOLineToPOLine(FromProdOrderLine, ToProdOrderLine, 0, true);
                    end;
                    ToProdOrderLine.Validate("Unit Cost", FromProdOrderLine."Unit Cost");
                    OnCopyFromProdOrderLine(ToProdOrderLine, FromProdOrderLine);
                    ToProdOrderLine.Modify();
                    NewStatusOption := NewStatus.AsInteger();
                    OnAfterToProdOrderLineModify(ToProdOrderLine, FromProdOrderLine, NewStatusOption);
                    NewStatus := Enum::"Production Order Status".FromInteger(NewStatusOption);
                end;
            until FromProdOrderLine.Next() = 0;
            OnAfterTransProdOrderLines(FromProdOrder, ToProdOrder);
            FromProdOrderLine.DeleteAll();
        end;
    end;

    local procedure GetNonInvtDirectCost(InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; var CostAmount: Decimal; var CostAmountACY: Decimal)
    var
        ValueEntry: Record "Value Entry";
    begin
        if InvtAdjmtEntryOrder."Order Type" <> InvtAdjmtEntryOrder."Order Type"::Production then
            exit;

        ValueEntry.SetLoadFields("Order Type", "Order No.", "Order Line No.", Inventoriable, "Cost Amount (Non-Invtbl.)", "Cost Amount (Non-Invtbl.)(ACY)");
        ValueEntry.SetRange("Order Type", ValueEntry."Order Type"::Production);
        ValueEntry.SetRange("Order No.", InvtAdjmtEntryOrder."Order No.");
        ValueEntry.SetRange("Order Line No.", InvtAdjmtEntryOrder."Order Line No.");
        ValueEntry.SetRange(Inventoriable, false);
        if not ValueEntry.IsEmpty() then begin
            ValueEntry.CalcSums("Cost Amount (Non-Invtbl.)", "Cost Amount (Non-Invtbl.)(ACY)");
            CostAmount := -ValueEntry."Cost Amount (Non-Invtbl.)";
            CostAmountACY := -ValueEntry."Cost Amount (Non-Invtbl.)(ACY)";
        end;
    end;

    local procedure UpdateSourceSubtypeForPutAwayDocumentWhenStatusIsChanged(ProdOrderLine: Record "Prod. Order Line"; NewProdOrderStatus: Enum "Production Order Status")
    begin
        UpdateWhseActivityLineForProdOutput(ProdOrderLine, NewProdOrderStatus);
        UpdateWhseWorksheetLineForProdOutput(ProdOrderLine, NewProdOrderStatus);
    end;

    local procedure UpdateWhseActivityLineForProdOutput(ProdOrderLine: Record "Prod. Order Line"; NewProdOrderStatus: Enum "Production Order Status")
    var
        WhseActivityLine: Record "Warehouse Activity Line";
    begin
        WhseActivityLine.SetLoadFields("Source Subtype");
        WhseActivityLine.SetRange("Activity Type", WhseActivityLine."Activity Type"::"Put-away");
        WhseActivityLine.SetRange("Source Type", Database::"Prod. Order Line");
        WhseActivityLine.SetRange("Source Subtype", ProdOrderLine.Status.AsInteger());
        WhseActivityLine.SetRange("Source Document", WhseActivityLine."Source Document"::"Prod. Output");
        WhseActivityLine.SetRange("Source No.", ProdOrderLine."Prod. Order No.");
        WhseActivityLine.SetRange("Source Line No.", ProdOrderLine."Line No.");
        WhseActivityLine.SetRange("Whse. Document Type", WhseActivityLine."Whse. Document Type"::Production);
        WhseActivityLine.SetRange("Whse. Document No.", ProdOrderLine."Prod. Order No.");
        WhseActivityLine.SetRange("Whse. Document Line No.", ProdOrderLine."Line No.");
        if not WhseActivityLine.IsEmpty() then
            WhseActivityLine.ModifyAll("Source Subtype", NewProdOrderStatus.AsInteger());
    end;

    local procedure UpdateWhseWorksheetLineForProdOutput(ProdOrderLine: Record "Prod. Order Line"; NewProdOrderStatus: Enum "Production Order Status")
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
    begin
        WhseWorksheetLine.SetLoadFields("Source Subtype");
        WhseWorksheetLine.SetRange("Source Type", Database::"Prod. Order Line");
        WhseWorksheetLine.SetRange("Source Subtype", ProdOrderLine.Status.AsInteger());
        WhseWorksheetLine.SetRange("Source Document", "Warehouse Journal Source Document"::"Prod. Output");
        WhseWorksheetLine.SetRange("Source No.", ProdOrderLine."Prod. Order No.");
        WhseWorksheetLine.SetRange("Source Line No.", ProdOrderLine."Line No.");
        WhseWorksheetLine.SetRange("Whse. Document Type", WhseWorksheetLine."Whse. Document Type"::Production);
        WhseWorksheetLine.SetRange("Whse. Document No.", ProdOrderLine."Prod. Order No.");
        WhseWorksheetLine.SetRange("Whse. Document Line No.", ProdOrderLine."Line No.");
        if not WhseWorksheetLine.IsEmpty() then
            WhseWorksheetLine.ModifyAll("Source Subtype", NewProdOrderStatus.AsInteger());
    end;

    local procedure InsertProdOrderLine(var ToProdOrderLine: Record "Prod. Order Line"; FromProdOrderLine: Record "Prod. Order Line")
    begin
        OnBeforeInsertProdOrderLine(ToProdOrderLine, FromProdOrderLine);
        ToProdOrderLine.Insert();
        OnAfterInsertProdOrderLine(ToProdOrderLine, FromProdOrderLine);
    end;

    local procedure TransProdOrderRtngLine(FromProdOrder: Record "Production Order")
    var
        FromProdOrderRtngLine: Record "Prod. Order Routing Line";
        ToProdOrderRtngLine: Record "Prod. Order Routing Line";
        ProdOrderCapNeed: Record "Prod. Order Capacity Need";
    begin
        FromProdOrderRtngLine.SetRange(Status, FromProdOrder.Status);
        FromProdOrderRtngLine.SetRange("Prod. Order No.", FromProdOrder."No.");
        FromProdOrderRtngLine.LockTable();
        if FromProdOrderRtngLine.FindSet() then begin
            repeat
                ToProdOrderRtngLine := FromProdOrderRtngLine;
                ToProdOrderRtngLine.Status := ToProdOrder.Status;
                ToProdOrderRtngLine."Prod. Order No." := ToProdOrder."No.";
                if ToProdOrder.Status = ToProdOrder.Status::Released then
                    ToProdOrderRtngLine."Routing Status" := FromProdOrderRtngLine."Routing Status"::Planned;
                if ToProdOrder.Status = ToProdOrder.Status::Finished then
                    ToProdOrderRtngLine."Routing Status" := FromProdOrderRtngLine."Routing Status"::Finished;

                if ToProdOrder.Status in [ToProdOrder.Status::"Firm Planned", ToProdOrder.Status::Released] then begin
                    ProdOrderCapNeed.SetRange("Prod. Order No.", FromProdOrder."No.");
                    ProdOrderCapNeed.SetRange(Status, FromProdOrder.Status);
                    ProdOrderCapNeed.SetRange("Routing Reference No.", FromProdOrderRtngLine."Routing Reference No.");
                    ProdOrderCapNeed.SetRange("Operation No.", FromProdOrderRtngLine."Operation No.");
                    ProdOrderCapNeed.SetRange("Requested Only", false);
                    ProdOrderCapNeed.CalcSums("Needed Time (ms)");
                    ToProdOrderRtngLine."Expected Capacity Need" := ProdOrderCapNeed."Needed Time (ms)";
                end;
                OnCopyFromProdOrderRoutingLine(ToProdOrderRtngLine, FromProdOrderRtngLine, NewPostingDate);
                ToProdOrderRtngLine.Insert();
                OnAfterToProdOrderRtngLineInsert(ToProdOrderRtngLine, FromProdOrderRtngLine);
            until FromProdOrderRtngLine.Next() = 0;
            FromProdOrderRtngLine.DeleteAll();
        end;
    end;

    local procedure TransProdOrderComp(FromProdOrder: Record "Production Order")
    var
        FromProdOrderComp: Record "Prod. Order Component";
        ToProdOrderComp: Record "Prod. Order Component";
        Location: Record Location;
        IsHandled: Boolean;
    begin
        OnBeforeTransProdOrderComp(FromProdOrder, ToProdOrder, IsHandled);
        if IsHandled then
            exit;
        FromProdOrderComp.SetRange(Status, FromProdOrder.Status);
        FromProdOrderComp.SetRange("Prod. Order No.", FromProdOrder."No.");
        FromProdOrderComp.LockTable();
        if FromProdOrderComp.FindSet() then begin
            repeat
                if Location.Get(FromProdOrderComp."Location Code") and
                   Location."Bin Mandatory" and
                   not Location."Directed Put-away and Pick" and
                   (FromProdOrderComp.Status = FromProdOrderComp.Status::"Firm Planned") and
                   (ToProdOrder.Status = ToProdOrder.Status::Released) and
                   (FromProdOrderComp."Flushing Method" in [FromProdOrderComp."Flushing Method"::Forward, FromProdOrderComp."Flushing Method"::"Pick + Forward"]) and
                   (FromProdOrderComp."Routing Link Code" = '') and
                   (FromProdOrderComp."Bin Code" = '')
                then
                    Error(
                      Text010,
                      FromProdOrderComp.FieldCaption("Bin Code"),
                      FromProdOrderComp.TableCaption,
                      FromProdOrderComp.FieldCaption("Line No."),
                      FromProdOrderComp."Line No.");
                ToProdOrderComp := FromProdOrderComp;
                ToProdOrderComp.Validate(Status, ToProdOrder.Status);
                ToProdOrderComp."Prod. Order No." := ToProdOrder."No.";
                OnTransProdOrderCompOnBeforeToProdOrderCompInsert(FromProdOrderComp, ToProdOrderComp);
                ToProdOrderComp.Insert();
                OnTransProdOrderCompOnAfterToProdOrderCompInsert(FromProdOrderComp, ToProdOrderComp);
                if NewStatus = NewStatus::Finished then begin
                    ReservMgt.SetReservSource(FromProdOrderComp);
                    ReservMgt.DeleteReservEntries(true, 0);
                end else begin
                    ToProdOrderComp.BlockDynamicTracking(true);
                    ToProdOrderComp.Validate("Expected Quantity");
                    ProdOrderCompReserve.TransferPOCompToPOComp(FromProdOrderComp, ToProdOrderComp, 0, true);
                    if ToProdOrderComp.Status in [ToProdOrderComp.Status::"Firm Planned", ToProdOrderComp.Status::Released] then
                        ToProdOrderComp.AutoReserve();
                end;
                OnCopyFromProdOrderComp(ToProdOrderComp, FromProdOrderComp);
                ToProdOrderComp.Modify();
            until FromProdOrderComp.Next() = 0;
            OnAfterTransProdOrderComp(FromProdOrder, ToProdOrder);
            FromProdOrderComp.DeleteAll();
        end;
    end;

    local procedure TransProdOrderRtngTool(FromProdOrder: Record "Production Order")
    var
        FromProdOrderRtngTool: Record "Prod. Order Routing Tool";
        ToProdOrderRoutTool: Record "Prod. Order Routing Tool";
    begin
        FromProdOrderRtngTool.SetRange(Status, FromProdOrder.Status);
        FromProdOrderRtngTool.SetRange("Prod. Order No.", FromProdOrder."No.");
        FromProdOrderRtngTool.LockTable();
        if FromProdOrderRtngTool.FindSet() then begin
            repeat
                ToProdOrderRoutTool := FromProdOrderRtngTool;
                ToProdOrderRoutTool.Status := ToProdOrder.Status;
                ToProdOrderRoutTool."Prod. Order No." := ToProdOrder."No.";
                ToProdOrderRoutTool.Insert();
            until FromProdOrderRtngTool.Next() = 0;
            FromProdOrderRtngTool.DeleteAll();
        end;
    end;

    local procedure TransProdOrderRtngPersnl(FromProdOrder: Record "Production Order")
    var
        FromProdOrderRtngPersonnel: Record "Prod. Order Routing Personnel";
        ToProdOrderRtngPersonnel: Record "Prod. Order Routing Personnel";
    begin
        FromProdOrderRtngPersonnel.SetRange(Status, FromProdOrder.Status);
        FromProdOrderRtngPersonnel.SetRange("Prod. Order No.", FromProdOrder."No.");
        FromProdOrderRtngPersonnel.LockTable();
        if FromProdOrderRtngPersonnel.FindSet() then begin
            repeat
                ToProdOrderRtngPersonnel := FromProdOrderRtngPersonnel;
                ToProdOrderRtngPersonnel.Status := ToProdOrder.Status;
                ToProdOrderRtngPersonnel."Prod. Order No." := ToProdOrder."No.";
                ToProdOrderRtngPersonnel.Insert();
            until FromProdOrderRtngPersonnel.Next() = 0;
            FromProdOrderRtngPersonnel.DeleteAll();
        end;
    end;

    local procedure TransProdOrdRtngQltyMeas(FromProdOrder: Record "Production Order")
    var
        FromProdOrderRtngQltyMeas: Record "Prod. Order Rtng Qlty Meas.";
        ToProdOrderRtngQltyMeas: Record "Prod. Order Rtng Qlty Meas.";
    begin
        FromProdOrderRtngQltyMeas.SetRange(Status, FromProdOrder.Status);
        FromProdOrderRtngQltyMeas.SetRange("Prod. Order No.", FromProdOrder."No.");
        FromProdOrderRtngQltyMeas.LockTable();
        if FromProdOrderRtngQltyMeas.FindSet() then begin
            repeat
                ToProdOrderRtngQltyMeas := FromProdOrderRtngQltyMeas;
                ToProdOrderRtngQltyMeas.Status := ToProdOrder.Status;
                ToProdOrderRtngQltyMeas."Prod. Order No." := ToProdOrder."No.";
                ToProdOrderRtngQltyMeas.Insert();
            until FromProdOrderRtngQltyMeas.Next() = 0;
            FromProdOrderRtngQltyMeas.DeleteAll();
        end;
    end;

    local procedure TransProdOrderCmtLine(FromProdOrder: Record "Production Order")
    var
        FromProdOrderCommentLine: Record "Prod. Order Comment Line";
        ToProdOrderCommentLine: Record "Prod. Order Comment Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransProdOrderCmtLine(FromProdOrder, ToProdOrder, IsHandled);
        if IsHandled then
            exit;

        FromProdOrderCommentLine.SetRange(Status, FromProdOrder.Status);
        FromProdOrderCommentLine.SetRange("Prod. Order No.", FromProdOrder."No.");
        FromProdOrderCommentLine.LockTable();
        if FromProdOrderCommentLine.FindSet() then begin
            repeat
                ToProdOrderCommentLine := FromProdOrderCommentLine;
                ToProdOrderCommentLine.Status := ToProdOrder.Status;
                ToProdOrderCommentLine."Prod. Order No." := ToProdOrder."No.";
                ToProdOrderCommentLine.Insert();
            until FromProdOrderCommentLine.Next() = 0;
            FromProdOrderCommentLine.DeleteAll();
        end;
        TransferLinks(FromProdOrder, ToProdOrder);
    end;

    local procedure TransProdOrderRtngCmtLn(FromProdOrder: Record "Production Order")
    var
        FromProdOrderRtngComment: Record "Prod. Order Rtng Comment Line";
        ToProdOrderRtngComment: Record "Prod. Order Rtng Comment Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransProdOrderRtngCmtLn(FromProdOrder, ToProdOrder, IsHandled);
        if IsHandled then
            exit;

        FromProdOrderRtngComment.SetRange(Status, FromProdOrder.Status);
        FromProdOrderRtngComment.SetRange("Prod. Order No.", FromProdOrder."No.");
        FromProdOrderRtngComment.LockTable();
        if FromProdOrderRtngComment.FindSet() then begin
            repeat
                ToProdOrderRtngComment := FromProdOrderRtngComment;
                ToProdOrderRtngComment.Status := ToProdOrder.Status;
                ToProdOrderRtngComment."Prod. Order No." := ToProdOrder."No.";
                ToProdOrderRtngComment.Insert();
            until FromProdOrderRtngComment.Next() = 0;
            FromProdOrderRtngComment.DeleteAll();
        end;
    end;

    local procedure TransProdOrderBOMCmtLine(FromProdOrder: Record "Production Order")
    var
        FromProdOrderBOMComment: Record "Prod. Order Comp. Cmt Line";
        ToProdOrderBOMComment: Record "Prod. Order Comp. Cmt Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransProdOrderBOMCmtLine(FromProdOrder, ToProdOrder, IsHandled);
        if IsHandled then
            exit;

        FromProdOrderBOMComment.SetRange(Status, FromProdOrder.Status);
        FromProdOrderBOMComment.SetRange("Prod. Order No.", FromProdOrder."No.");
        FromProdOrderBOMComment.LockTable();
        if FromProdOrderBOMComment.FindSet() then begin
            repeat
                ToProdOrderBOMComment := FromProdOrderBOMComment;
                ToProdOrderBOMComment.Status := ToProdOrder.Status;
                ToProdOrderBOMComment."Prod. Order No." := ToProdOrder."No.";
                ToProdOrderBOMComment.Insert();
            until FromProdOrderBOMComment.Next() = 0;
            FromProdOrderBOMComment.DeleteAll();
        end;
    end;

    local procedure TransProdOrderCapNeed(FromProdOrder: Record "Production Order")
    var
        FromProdOrderCapNeed: Record "Prod. Order Capacity Need";
        ToProdOrderCapNeed: Record "Prod. Order Capacity Need";
        IsHandled: Boolean;
    begin
        FromProdOrderCapNeed.SetRange(Status, FromProdOrder.Status);
        FromProdOrderCapNeed.SetRange("Prod. Order No.", FromProdOrder."No.");
        FromProdOrderCapNeed.SetRange("Requested Only", false);
        if NewStatus = NewStatus::Finished then begin
            IsHandled := false;
            OnTransProdOrderCapNeedOnBeforeDeleteAll(ToProdOrder, FromProdOrderCapNeed, IsHandled);
            if not IsHandled then
                FromProdOrderCapNeed.DeleteAll();
        end else begin
            FromProdOrderCapNeed.LockTable();
            if FromProdOrderCapNeed.FindSet() then begin
                repeat
                    ToProdOrderCapNeed := FromProdOrderCapNeed;
                    ToProdOrderCapNeed.Status := ToProdOrder.Status;
                    ToProdOrderCapNeed."Prod. Order No." := ToProdOrder."No.";
                    ToProdOrderCapNeed."Allocated Time" := ToProdOrderCapNeed."Needed Time";
                    OnCopyFromProdOrderCapacityNeed(ToProdOrderCapNeed, FromProdOrderCapNeed);
                    ToProdOrderCapNeed.Insert();
                until FromProdOrderCapNeed.Next() = 0;
                FromProdOrderCapNeed.DeleteAll();
            end;
        end;
    end;

    local procedure IsVariantCodeMandatory(ProdOrder: Record "Production Order"): Boolean
    var
        VariantItem: Record Item;
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange(Status, ProdOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrder."No.");
        ProdOrderLine.SetFilter("Remaining Quantity", '<>0');
        if ProdOrderLine.FindSet() then
            repeat
                VariantItem.Get(ProdOrderLine."Item No.");
                if VariantItem.IsVariantMandatory(VariantItem."Variant Mandatory if Exists" = VariantItem."Variant Mandatory if Exists"::Yes) then begin
                    ProdOrderLine.TestField("Variant Code", ErrorInfo.Create());
                    exit(ProdOrderLine."Variant Code" = '');
                end;
            until ProdOrderLine.Next() = 0;
    end;

    procedure FlushProdOrder(ProdOrder: Record "Production Order"; NewStatus: Enum "Production Order Status"; PostingDate: Date)
    var
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        ProdOrderLine: Record "Prod. Order Line";
        SuppliedByProdOrderLine: Record "Prod. Order Line";
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        ProdOrderComp: Record "Prod. Order Component";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        Window: Dialog;
        QtyToPost: Decimal;
        NoOfRecords: Integer;
        LineCount: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFlushProdOrder(ProdOrder, NewStatus, PostingDate, IsHandled);
        if IsHandled then
            exit;

        if IsStatusSimulatedOrPlanned(NewStatus) then
            exit;

        GetSourceCodeSetup();

        ProdOrderLine.LockTable();
        ProdOrderLine.Reset();
        ProdOrderLine.SetRange(Status, ProdOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrder."No.");
        if ProdOrderLine.FindSet() then
            repeat
                ProdOrderRtngLine.SetCurrentKey("Prod. Order No.", Status, "Flushing Method");
                if NewStatus = NewStatus::Released then
                    ProdOrderRtngLine.SetRange("Flushing Method", ProdOrderRtngLine."Flushing Method"::Forward)
                else begin
                    ProdOrderRtngLine.Ascending(false); // In case of backward flushing on the last operation
                    ProdOrderRtngLine.SetRange("Flushing Method", ProdOrderRtngLine."Flushing Method"::Backward);
                end;
                ProdOrderRtngLine.SetRange(Status, ProdOrderLine.Status);
                ProdOrderRtngLine.SetRange("Prod. Order No.", ProdOrder."No.");
                ProdOrderRtngLine.SetRange("Routing No.", ProdOrderLine."Routing No.");
                ProdOrderRtngLine.SetRange("Routing Reference No.", ProdOrderLine."Routing Reference No.");
                ProdOrderRtngLine.LockTable();
                FlushProdOrderProcessProdOrderRtngLine(ProdOrder, ProdOrderLine, ProdOrderRtngLine, PostingDate);
                OnFlushProdOrderOnAfterProdOrderLineLoopIteration(ProdOrderLine, NewStatus, PostingDate);
            until ProdOrderLine.Next() = 0;

        ProdOrderComp.SetCurrentKey(Status, "Prod. Order No.", "Routing Link Code", "Flushing Method");
        if NewStatus = NewStatus::Released then
            ProdOrderComp.SetFilter(
              "Flushing Method",
              '%1|%2',
              ProdOrderComp."Flushing Method"::Forward,
              ProdOrderComp."Flushing Method"::"Pick + Forward")
        else
            ProdOrderComp.SetFilter(
              "Flushing Method",
              '%1|%2',
              ProdOrderComp."Flushing Method"::Backward,
              ProdOrderComp."Flushing Method"::"Pick + Backward");
        ProdOrderComp.SetRange("Routing Link Code", '');
        ProdOrderComp.SetRange(Status, ProdOrderComp.Status::Released);
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrder."No.");
        ProdOrderComp.SetFilter("Item No.", '<>%1', '');
        ProdOrderComp.LockTable();
        OnFlushProdOrderOnAfterProdOrderCompSetFilters(ProdOrder, ProdOrderComp);
        if ProdOrderComp.FindSet() then begin
            NoOfRecords := ProdOrderComp.Count;
            Window.Open(
              Text002 +
              Text003);
            LineCount := 0;

            repeat
                LineCount := LineCount + 1;
                Item.Get(ProdOrderComp."Item No.");
                Item.TestField("Rounding Precision");
                Window.Update(1, LineCount);
                Window.Update(2, Round(LineCount / NoOfRecords * 10000, 1));
                ProdOrderLine.Get(ProdOrderComp.Status, ProdOrder."No.", ProdOrderComp."Prod. Order Line No.");
                if NewStatus = NewStatus::Released then
                    QtyToPost := ProdOrderComp.GetNeededQty(1, false)
                else begin
                    if ProdOrder.Reopened then
                        QtyToPost := ProdOrderComp.GetNeededQty(0, true)
                    else
                        QtyToPost := ProdOrderComp.GetNeededQty(0, false);

                    if SuppliedByProdOrderLine.Get(ProdOrderComp.Status, ProdOrderComp."Prod. Order No.", ProdOrderComp."Supplied-by Line No.") and
                       (SuppliedByProdOrderLine."Remaining Quantity" = 0) and
                       (SuppliedByProdOrderLine.Quantity = SuppliedByProdOrderLine."Finished Quantity")
                    then
                        QtyToPost := ProdOrderComp.GetNeededQty(1, false);
                end;

                OnAfterCalculateQtyToPost(ProdOrderComp, QtyToPost, ProdOrder, NewStatus);
                RoundQtyToPost(ProdOrderComp, Item, QtyToPost);

                if QtyToPost <> 0 then begin
                    InitItemJnlLineFromProdOrderComp(ItemJnlLine, ProdOrder, ProdOrderLine, ProdOrderComp, PostingDate, QtyToPost);
                    ItemJnlLine."Gen. Prod. Posting Group" := Item."Gen. Prod. Posting Group";
                    OnFlushProdOrderOnBeforeCopyItemTracking(ItemJnlLine, ProdOrderComp, Item);
                    if Item."Item Tracking Code" <> '' then
                        ItemTrackingMgt.CopyItemTracking(ProdOrderComp.RowID1(), ItemJnlLine.RowID1(), false);
                    PostFlushItemJnlLine(ProdOrderLine, ItemJnlLine);
                    OnFlushProdOrderOnAfterPostFlushItemJnlLine(ItemJnlLine);
                end;
            until ProdOrderComp.Next() = 0;
            Window.Close();
        end;
    end;

    local procedure RoundQtyToPost(ProdOrderComp: Record "Prod. Order Component"; Item: Record Item; var QtyToPost: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRoundQtyToPost(ProdOrderComp, QtyToPost, IsHandled);
        if IsHandled then
            exit;

        QtyToPost := UOMMgt.RoundToItemRndPrecision(QtyToPost, Item."Rounding Precision");

        OnAfterRoundQtyToPost(ProdOrderComp, QtyToPost);
    end;

    local procedure FlushProdOrderProcessProdOrderRtngLine(ProdOrder: Record "Production Order"; ProdOrderLine: Record "Prod. Order Line"; var ProdOrderRtngLine: Record "Prod. Order Routing Line"; PostingDate: Date)
    var
        ItemJnlLine: Record "Item Journal Line";
        IsLastOperation: Boolean;
        ActualOutputAndScrapQty: Decimal;
        ActualOutputAndScrapQtyBase: Decimal;
        PutawayQtyBaseToCalc: Decimal;
        OutputQty: Decimal;
        OutputQtyBase: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFlushProdOrderProcessProdOrderRtngLine(ProdOrderLine, ProdOrderRtngLine, PostingDate, IsHandled);
        if IsHandled then
            exit;

        if ProdOrderRtngLine.Find('-') then begin
            // First found operation
            IsLastOperation := ProdOrderRtngLine."Next Operation No." = '';
            OnFlushProdOrderOnAfterFindProdOrderRtngLine(ProdOrderRtngLine, IsLastOperation);
            if ProdOrderRtngLine."Flushing Method" = ProdOrderRtngLine."Flushing Method"::Backward then begin
                ActualOutputAndScrapQtyBase :=
                  MfgCostCalcMgt.CalcActOperOutputAndScrap(ProdOrderLine, ProdOrderRtngLine);
                ActualOutputAndScrapQty := ActualOutputAndScrapQtyBase / ProdOrderLine."Qty. per Unit of Measure";
                PutawayQtyBaseToCalc := MfgCostCalcMgt.CalcActualOutputQtyWithNoCapacity(ProdOrderLine, ProdOrderRtngLine);
            end;

            if (ProdOrderRtngLine."Flushing Method" = ProdOrderRtngLine."Flushing Method"::Forward) or IsLastOperation then begin
                OutputQty := ProdOrderLine."Remaining Quantity";
                OutputQtyBase := ProdOrderLine."Remaining Qty. (Base)";
            end else
                if not IsLastOperation then begin // Not Last Operation
                    OutputQty := ActualOutputAndScrapQty;
                    OutputQtyBase := ActualOutputAndScrapQtyBase;
                    PutawayQtyBaseToCalc := 0;
                end;
            OnFlushProdOrderProcessProdOrderRtngLineOnAfterCalcOutputQty(ProdOrderLine, ProdOrderRtngLine, OutputQty, OutputQtyBase);

            repeat
                IsLastOperation := ProdOrderRtngLine."Next Operation No." = '';
                OnFlushProdOrderOnAfterFindProdOrderRtngLine(ProdOrderRtngLine, IsLastOperation);
                InitItemJnlLineFromProdOrderLine(ItemJnlLine, ProdOrder, ProdOrderLine, ProdOrderRtngLine, PostingDate);
                if ProdOrderRtngLine."Concurrent Capacities" = 0 then
                    ProdOrderRtngLine."Concurrent Capacities" := 1;
                SetTimeAndQuantityOmItemJnlLine(
                  ItemJnlLine, ProdOrderRtngLine, OutputQtyBase,
                  GetOutputQtyForProdOrderRoutingLine(ProdOrderLine, ProdOrderRtngLine, IsLastOperation, OutputQty),
                  PutawayQtyBaseToCalc);
                ItemJnlLine."Concurrent Capacity" := ProdOrderRtngLine."Concurrent Capacities";
                ItemJnlLine."Source Code" := SourceCodeSetup.Flushing;
                if not (ItemJnlLine.TimeIsEmpty() and (ItemJnlLine."Output Quantity" = 0)) then begin
                    DimMgt.UpdateGlobalDimFromDimSetID(
                      ItemJnlLine."Dimension Set ID", ItemJnlLine."Shortcut Dimension 1 Code", ItemJnlLine."Shortcut Dimension 2 Code");
                    OnAfterUpdateGlobalDim(ItemJnlLine, ProdOrderRtngLine, ProdOrderLine);
                    if IsLastOperation then
                        ProdOrderLineReserve.TransferPOLineToItemJnlLine(ProdOrderLine, ItemJnlLine, ItemJnlLine."Output Quantity (Base)");
                    PostFlushItemJnlLine(ProdOrderLine, ItemJnlLine);
                end;

                if (ProdOrderRtngLine."Flushing Method" = ProdOrderRtngLine."Flushing Method"::Backward) and IsLastOperation then begin
                    OutputQty += ActualOutputAndScrapQty;
                    OutputQtyBase += ActualOutputAndScrapQtyBase;
                    PutawayQtyBaseToCalc := 0;
                end;
            until ProdOrderRtngLine.Next() = 0;
        end;

        OnAfterFlushProdOrderProcessProdOrderRtngLine(ProdOrder, ProdOrderLine, ProdOrderRtngLine, NewStatus.AsInteger(), PostingDate);
    end;

    local procedure PostFlushItemJnlLine(ProdOrderLine: Record "Prod. Order Line"; var ItemJnlLine: Record "Item Journal Line")
    var
        LatestProdOrderLine: Record "Prod. Order Line";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostFlushItemJnlLine(ItemJnlLine, IsHandled);
        if IsHandled then
            exit;

        ItemJnlPostLine.RunWithCheck(ItemJnlLine);
        LatestProdOrderLine.Get(ProdOrderLine.Status, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.");
        HandleWhsePutAwayForProdOutput(LatestProdOrderLine, ItemJnlLine);
    end;

    local procedure HandleWhsePutAwayForProdOutput(ProdOrderLine: Record "Prod. Order Line"; ItemJnlLine: Record "Item Journal Line")
    begin
        if ItemJnlLine.OutputValuePosting() then
            exit;

        if ItemJnlLine."Entry Type" <> ItemJnlLine."Entry Type"::Output then
            exit;

        if (ItemJnlLine."Order No." = '') or (ItemJnlLine."Order Line No." = 0) then
            exit;

        if not MfgCreatePutaway.ShouldCreateWhsePutAwayForProdOutput(ItemJnlLine) then
            exit;

        MfgCreatePutaway.CreateWhsePutAwayForProdOrderOutputLine(ProdOrderLine);
    end;

    local procedure InitItemJnlLineFromProdOrderLine(var ItemJnlLine: Record "Item Journal Line"; ProdOrder: Record "Production Order"; ProdOrderLine: Record "Prod. Order Line"; ProdOrderRoutingLine: Record "Prod. Order Routing Line"; PostingDate: Date)
    begin
        ItemJnlLine.Init();
        OnInitItemJnlLineFromProdOrderLineOnAfterInit(ItemJnlLine);

        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Output);
        ItemJnlLine.Validate("Posting Date", PostingDate);
        ItemJnlLine."Document No." := ProdOrder."No.";
        ItemJnlLine.Validate("Order Type", ItemJnlLine."Order Type"::Production);
        ItemJnlLine.Validate("Order No.", ProdOrder."No.");
        ItemJnlLine.Validate("Order Line No.", ProdOrderLine."Line No.");
        ItemJnlLine.Validate("Item No.", ProdOrderLine."Item No.");
        ItemJnlLine.Validate("Routing Reference No.", ProdOrderRoutingLine."Routing Reference No.");
        ItemJnlLine.Validate("Routing No.", ProdOrderRoutingLine."Routing No.");
        ItemJnlLine.Validate("Variant Code", ProdOrderLine."Variant Code");
        ItemJnlLine."Location Code" := ProdOrderLine."Location Code";
        ItemJnlLine.Validate("Bin Code", ProdOrderLine."Bin Code");
        if ItemJnlLine."Unit of Measure Code" <> ProdOrderLine."Unit of Measure Code" then
            ItemJnlLine.Validate("Unit of Measure Code", ProdOrderLine."Unit of Measure Code");
        ItemJnlLine.Validate("Operation No.", ProdOrderRoutingLine."Operation No.");
        if ItemJnlLine."Unit of Measure Code" <> ProdOrderLine."Unit of Measure Code" then
            ItemJnlLine.Validate("Unit of Measure Code", ProdOrderLine."Unit of Measure Code");
        ItemJnlLine.Validate("Operation No.", ProdOrderRoutingLine."Operation No.");

        OnAfterInitItemJnlLineFromProdOrderLine(ItemJnlLine, ProdOrder, ProdOrderLine, ProdOrderRoutingLine);
    end;

    local procedure InitItemJnlLineFromProdOrderComp(var ItemJnlLine: Record "Item Journal Line"; ProdOrder: Record "Production Order"; ProdOrderLine: Record "Prod. Order Line"; ProdOrderComp: Record "Prod. Order Component"; PostingDate: Date; QtyToPost: Decimal)
    var
        UnitOfMeasureManagement: Codeunit "Unit of Measure Management";
    begin
        ItemJnlLine.Init();
        OnInitItemJnlLineFromProdOrderCompOnAfterInit(ItemJnlLine);

        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Consumption);
        ItemJnlLine.Validate("Posting Date", PostingDate);
        ItemJnlLine."Order Type" := ItemJnlLine."Order Type"::Production;
        ItemJnlLine."Order No." := ProdOrder."No.";
        ItemJnlLine."Source No." := ProdOrderLine."Item No.";
        ItemJnlLine."Source Type" := ItemJnlLine."Source Type"::Item;
        ItemJnlLine."Order Line No." := ProdOrderLine."Line No.";
        ItemJnlLine."Document No." := ProdOrder."No.";
        ItemJnlLine.Validate("Item No.", ProdOrderComp."Item No.");
        ItemJnlLine.Validate("Prod. Order Comp. Line No.", ProdOrderComp."Line No.");
        if ItemJnlLine."Unit of Measure Code" <> ProdOrderComp."Unit of Measure Code" then
            ItemJnlLine.Validate("Unit of Measure Code", ProdOrderComp."Unit of Measure Code");
        ItemJnlLine."Qty. per Unit of Measure" := ProdOrderComp."Qty. per Unit of Measure";
        ItemJnlLine.Description := ProdOrderComp.Description;
        ItemJnlLine.Validate(Quantity, QtyToPost);
        if Abs(ItemJnlLine."Quantity (Base)" - ProdOrderComp."Qty. Picked (Base)") <= UnitOfMeasureManagement.QtyRndPrecision() then
            ItemJnlLine."Quantity (Base)" := ProdOrderComp."Qty. Picked (Base)";
        ItemJnlLine.Validate("Unit Cost", ProdOrderComp."Unit Cost");
        ItemJnlLine."Location Code" := ProdOrderComp."Location Code";
        ItemJnlLine."Bin Code" := ProdOrderComp."Bin Code";
        ItemJnlLine."Variant Code" := ProdOrderComp."Variant Code";
        ItemJnlLine."Source Code" := SourceCodeSetup.Flushing;
        ItemJnlLine."Gen. Bus. Posting Group" := ProdOrder."Gen. Bus. Posting Group";
        ItemJnlLine."Gen. Prod. Posting Group" := Item."Gen. Prod. Posting Group";
        OnAfterInitItemJnlLineFromProdOrderComp(ItemJnlLine, ProdOrder, ProdOrderLine, ProdOrderComp);
    end;

    procedure CheckBeforeFinishProdOrder(ProdOrder: Record "Production Order")
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComp: Record "Prod. Order Component";
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        PurchLine: Record "Purchase Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckBeforeFinishProdOrder(ProdOrder, IsHandled);
        if IsHandled then
            exit;

        PurchLine.SetCurrentKey("Document Type", Type, "Prod. Order No.", "Prod. Order Line No.", "Routing No.", "Operation No.");
        PurchLine.SetLoadFields("Document No.");
        PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
        PurchLine.SetRange(Type, PurchLine.Type::Item);
        PurchLine.SetRange("Prod. Order No.", ProdOrder."No.");
        PurchLine.SetFilter("Outstanding Quantity", '<>%1', 0);
        OnCheckBeforeFinishProdOrderOnAfterSetProdOrderCompFilters(ProdOrderComp, ProdOrder, PurchLine);
        if PurchLine.FindFirst() then
            Error(Text008, ProdOrder.TableCaption(), ProdOrder."No.", PurchLine."Document No.");

        OnCheckBeforeFinishProdOrderOnAfterCheckProdOrder(ProdOrder);

        CheckBeforeSetStatusToFinishProdOrder(ProdOrder, ProdOrderLine, ProdOrderRtngLine, ProdOrderComp);
    end;

    local procedure CheckBeforeSetStatusToFinishProdOrder(ProdOrder: Record "Production Order"; ProdOrderLine: Record "Prod. Order Line"; ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ProdOrderComponent: Record "Prod. Order Component")
    var
        ConfirmManagement: Codeunit "Confirm Management";
        ShowOutputWarning: Boolean;
        ShowConsumptionWarning: Boolean;
        IsHandled: Boolean;
    begin
        ShowOutputWarning := false;
        ProdOrderLine.SetLoadFields("Routing No.", "Routing Reference No.");
        ProdOrderRoutingLine.SetLoadFields("Prod. Order No.");
        ProdOrderLine.SetRange(Status, ProdOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrder."No.");
        ProdOrderLine.SetFilter("Remaining Quantity", '<>0');
        IsHandled := false;
        OnCheckBeforeFinishProdOrderOnBeforeFindSet(ProdOrderLine, ProdOrderRoutingLine, ShowOutputWarning, IsHandled);
        if not IsHandled then
            if ProdOrderLine.Find('-') then
                repeat
                    ProdOrderRoutingLine.SetRange(Status, ProdOrderLine.Status);
                    ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
                    if ProdOrderLine."Routing Reference No." <> 0 then
                        ProdOrderRoutingLine.SetRange("Routing Reference No.", ProdOrderLine."Routing Reference No.")
                    else
                        ProdOrderRoutingLine.SetRange("Routing No.", ProdOrderLine."Routing No.");
                    ProdOrderRoutingLine.SetRange("Next Operation No.", '');
                    ProdOrderRoutingLine.SetRange("Flushing Method");
                    if not ProdOrderRoutingLine.IsEmpty() then begin
                        ProdOrderRoutingLine.SetFilter("Flushing Method", '<>%1', ProdOrderRoutingLine."Flushing Method"::Backward);
                        ShowOutputWarning := not ProdOrderRoutingLine.IsEmpty();
                    end else
                        ShowOutputWarning := true;
                until (ProdOrderLine.Next() = 0) or ShowOutputWarning;

        OnCheckMissingOutput(ProdOrder, ProdOrderLine, ProdOrderRoutingLine, ShowOutputWarning);

        ShowConsumptionWarning := false;
        SetProdOrderCompFilters(ProdOrderComponent, ProdOrder);
        if ProdOrderComponent.FindSet() then
            repeat
                CheckNothingRemainingToPickForProdOrderComp(ProdOrderComponent);
                if ((ProdOrderComponent."Flushing Method" <> ProdOrderComponent."Flushing Method"::Backward) and
                    (ProdOrderComponent."Flushing Method" <> ProdOrderComponent."Flushing Method"::"Pick + Backward") and
                    (ProdOrderComponent."Routing Link Code" = '')) or
                   ((ProdOrderComponent."Routing Link Code" <> '') and not RtngWillFlushComp(ProdOrderComponent)) or
                   ((ProdOrderComponent."Flushing Method" in [ProdOrderComponent."Flushing Method"::Manual, ProdOrderComponent."Flushing Method"::"Pick + Manual"]) and
                   (ProdOrderComponent."Routing Link Code" <> ''))
                then
                    ShowConsumptionWarning := true;
            until ProdOrderComponent.Next() = 0;

        OnCheckMissingConsumption(ProdOrder, ProdOrderLine, ProdOrderRoutingLine, ShowConsumptionWarning);

        case true of
            ShowOutputWarning and not ShowConsumptionWarning:
                if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(FinishOrderWithOutputWarningQst, ProdOrder.TableCaption(), ProdOrder."No."), true) then
                    Error(Text005);

            ShowConsumptionWarning and not ShowOutputWarning:
                if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(FinishOrderWithConsumptionWarningQst, ProdOrder.TableCaption(), ProdOrder."No."), true) then
                    Error(Text005);

            ShowOutputWarning and ShowConsumptionWarning:
                if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(FinishOrderWithOutputAndConsumptionWarningQst, ProdOrder.TableCaption(), ProdOrder."No."), true) then
                    Error(Text005);
        end;
    end;

    local procedure RtngWillFlushComp(ProdOrderComp: Record "Prod. Order Component"): Boolean
    var
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        if ProdOrderComp."Routing Link Code" = '' then
            exit;

        ProdOrderLine.Get(ProdOrderComp.Status, ProdOrderComp."Prod. Order No.", ProdOrderComp."Prod. Order Line No.");

        ProdOrderRtngLine.SetCurrentKey("Prod. Order No.", Status, "Flushing Method");
        ProdOrderRtngLine.SetRange("Flushing Method", ProdOrderRtngLine."Flushing Method"::Backward);
        ProdOrderRtngLine.SetRange(Status, ProdOrderRtngLine.Status::Released);
        ProdOrderRtngLine.SetRange("Prod. Order No.", ProdOrderComp."Prod. Order No.");
        ProdOrderRtngLine.SetRange("Routing Link Code", ProdOrderComp."Routing Link Code");
        ProdOrderRtngLine.SetRange("Routing No.", ProdOrderLine."Routing No.");
        ProdOrderRtngLine.SetRange("Routing Reference No.", ProdOrderLine."Routing Reference No.");
        exit(not ProdOrderRtngLine.IsEmpty());
    end;

    local procedure GetSourceCodeSetup()
    begin
        if not SourceCodeSetupRead then
            SourceCodeSetup.Get();
        SourceCodeSetupRead := true;
    end;

    procedure SetPostingInfo(Status: Enum "Production Order Status"; PostingDate: Date; UpdateUnitCost: Boolean)
    begin
        NewStatus := Status;
        NewPostingDate := PostingDate;
        NewUpdateUnitCost := UpdateUnitCost;
    end;

    local procedure ErrorIfUnableToClearWIP(ProdOrder: Record "Production Order")
    var
        ProdOrderLine: Record "Prod. Order Line";
        IsHandled: Boolean;
    begin
        ProdOrderLine.SetRange(Status, ProdOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrder."No.");
        OnErrorIfUnableToClearWIPOnAfterProdOrderLineSetFilters(ProdOrder, ProdOrderLine);
        if ProdOrderLine.FindSet() then
            repeat
                IsHandled := false;
                OnErrorIfUnableToClearWIPOnBeforeError(ProdOrderLine, IsHandled);
                if not IsHandled then
                    if not OutputExists(ProdOrderLine) then
                        if MatrOrCapConsumpExists(ProdOrderLine) then
                            if not FinishOrderWithoutOutput then
                                Error(Text009, ProdOrderLine."Line No.", ToProdOrder.TableCaption(), ProdOrderLine."Prod. Order No.");
            until ProdOrderLine.Next() = 0;
    end;

    procedure OutputExists(ProdOrderLine: Record "Prod. Order Line"): Boolean
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        ItemLedgEntry.SetCurrentKey("Order Type", "Order No.", "Order Line No.");
        ItemLedgEntry.SetRange("Order Type", ItemLedgEntry."Order Type"::Production);
        ItemLedgEntry.SetRange("Order No.", ProdOrderLine."Prod. Order No.");
        ItemLedgEntry.SetRange("Order Line No.", ProdOrderLine."Line No.");
        ItemLedgEntry.SetRange("Entry Type", ItemLedgEntry."Entry Type"::Output);
        if ItemLedgEntry.FindFirst() then begin
            ItemLedgEntry.CalcSums(Quantity);
            if ItemLedgEntry.Quantity <> 0 then
                exit(true)
        end;
        exit(false);
    end;

    procedure MatrOrCapConsumpExists(ProdOrderLine: Record "Prod. Order Line") EntriesExist: Boolean
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        CapLedgEntry: Record "Capacity Ledger Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeMatrOrCapConsumpExists(ProdOrderLine, EntriesExist, IsHandled);
        if IsHandled then
            exit(EntriesExist);

        ItemLedgEntry.SetCurrentKey("Order Type", "Order No.", "Order Line No.");
        ItemLedgEntry.SetRange("Order Type", ItemLedgEntry."Order Type"::Production);
        ItemLedgEntry.SetRange("Order No.", ProdOrderLine."Prod. Order No.");
        ItemLedgEntry.SetRange("Order Line No.", ProdOrderLine."Line No.");
        ItemLedgEntry.SetRange("Entry Type", ItemLedgEntry."Entry Type"::Consumption);
        if not ItemLedgEntry.IsEmpty() then
            exit(true);

        CapLedgEntry.SetCurrentKey("Order Type", "Order No.", "Order Line No.", "Routing No.", "Routing Reference No.");
        CapLedgEntry.SetRange("Order Type", CapLedgEntry."Order Type"::Production);
        CapLedgEntry.SetRange("Order No.", ProdOrderLine."Prod. Order No.");
        CapLedgEntry.SetRange("Order Line No.", ProdOrderLine."Line No.");
        CapLedgEntry.SetRange("Routing No.", ProdOrderLine."Routing No.");
        CapLedgEntry.SetRange("Routing Reference No.", ProdOrderLine."Routing Reference No.");
        exit(not CapLedgEntry.IsEmpty);
    end;

    procedure SetTimeAndQuantityOmItemJnlLine(var ItemJnlLine: Record "Item Journal Line"; ProdOrderRtngLine: Record "Prod. Order Routing Line"; OutputQtyBase: Decimal; OutputQty: Decimal; PutawayQtyBaseToCalc: Decimal)
    begin
        if ItemJnlLine.SubcontractingWorkCenterUsed() then begin
            ItemJnlLine.Validate("Output Quantity", 0);
            ItemJnlLine.Validate("Run Time", 0);
            ItemJnlLine.Validate("Setup Time", 0)
        end else begin
            ItemJnlLine.Validate(
              "Setup Time",
              Round(
                ProdOrderRtngLine."Setup Time" *
                ProdOrderRtngLine."Concurrent Capacities" *
                CalendarMgt.QtyperTimeUnitofMeasure(
                  ProdOrderRtngLine."Work Center No.",
                  ProdOrderRtngLine."Setup Time Unit of Meas. Code"),
                UOMMgt.TimeRndPrecision()));
            ItemJnlLine.Validate(
              "Run Time",
              MfgCostCalcMgt.CalculateCostTime(
                OutputQtyBase + PutawayQtyBaseToCalc,
                ProdOrderRtngLine."Setup Time", ProdOrderRtngLine."Setup Time Unit of Meas. Code",
                ProdOrderRtngLine."Run Time", ProdOrderRtngLine."Run Time Unit of Meas. Code",
                ProdOrderRtngLine."Lot Size",
                ProdOrderRtngLine."Scrap Factor % (Accumulated)", ProdOrderRtngLine."Fixed Scrap Qty. (Accum.)",
                ProdOrderRtngLine."Work Center No.", Enum::"Unit Cost Calculation Type"::Time, false, 0));
            ItemJnlLine.Validate("Output Quantity", OutputQty);
            OnAfterSetTimeAndQuantityOmItemJnlLine(ItemJnlLine, ProdOrderRtngLine, OutputQtyBase, OutputQty);
        end;
    end;

    local procedure GetOutputQtyForProdOrderRoutingLine(ProdOrderLine: Record "Prod. Order Line"; ProdOrderRtngLine: Record "Prod. Order Routing Line"; IsLastOperation: Boolean; LastOutputQty: Decimal): Decimal
    var
        OutputQty: Decimal;
    begin
        if (ProdOrderRtngLine."Flushing Method" = ProdOrderRtngLine."Flushing Method"::Forward) or IsLastOperation then
            exit(LastOutputQty);
        OutputQty := LastOutputQty -
          MfgCostCalcMgt.CalcActOutputQtyBase(ProdOrderLine, ProdOrderRtngLine) / ProdOrderLine."Qty. per Unit of Measure";
        if OutputQty > 0 then
            exit(OutputQty);
        exit(0);
    end;

    local procedure TransferLinks(FromProdOrder: Record "Production Order"; ToProdOrder: Record "Production Order")
    var
        RecordLink: Record "Record Link";
        PageManagement: Codeunit "Page Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransferLinks(FromProdOrder, ToProdOrder, IsHandled);
        if IsHandled then
            exit;

        IsHandled := false;
        OnTransferLinksOnBeforeCopyLinks(FromProdOrder, ToProdOrder, IsHandled);
        if not IsHandled then
            ToProdOrder.CopyLinks(FromProdOrder);
        RecordLink.SetRange("Record ID", FromProdOrder.RecordId);
        RecordLink.DeleteAll();

        RecordLink.SetRange("Record ID", ToProdOrder.RecordId);
        RecordLink.SetRange(Type, RecordLink.Type::Note);
        if RecordLink.FindSet(true) then
            repeat
                RecordLink.Validate(
                  URL1, GetUrl(DefaultClientType, CompanyName, OBJECTTYPE::Page, PageManagement.GetPageID(ToProdOrder), ToProdOrder));
                RecordLink.Validate(
                  Description,
                  StrSubstNo(
                    '%1 - %2 - %3',
                    PageManagement.GetPageCaption(PageManagement.GetPageID(ToProdOrder)),
                    ToProdOrder."No.", ToProdOrder.Description));
                RecordLink.Modify(true);
            until RecordLink.Next() = 0;
    end;

    local procedure IsStatusSimulatedOrPlanned(Status: Enum "Production Order Status"): Boolean
    begin
        exit((Status = Status::Simulated) or (Status = Status::Planned) or (Status = Status::"Firm Planned"));
    end;

    local procedure SetProdOrderCompFilters(var ProdOrderComponent: Record "Prod. Order Component"; ProductionOrder: Record "Production Order")
    begin
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.SetFilter("Remaining Quantity", '<>0');

        OnAfterSetProdOrderCompFilters(ProdOrderComponent, ProductionOrder);
    end;

    local procedure ShowStatusMessage(ProdOrder: Record "Production Order")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowStatusMessage(ProdOrder, ToProdOrder, IsHandled);
        if IsHandled then
            exit;

        Message(Text000, ProdOrder.Status, ProdOrder.TableCaption(), ProdOrder."No.", ToProdOrder.Status, ToProdOrder.TableCaption(), ToProdOrder."No.");
    end;

    procedure ChangeProdOrderStatus(ProdOrder: Record "Production Order"; var NewProdOrder: Record "Production Order"; NewStatus: Enum "Production Order Status"; NewPostingDate: Date; NewUpdateUnitCost: Boolean)
    begin
        ChangeProdOrderStatus(ProdOrder, NewStatus, NewPostingDate, NewUpdateUnitCost);
        NewProdOrder := ToProdOrder;
    end;

    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure ChangeStatusWithSelectionFilter(var ProductionOrder: Record "Production Order")
    var
        TempErrors: Record "Error Message" temporary;
        ProdOrderChangeStatusBulk: Codeunit ProdOrderChangeStatusBulk;
        ChangeStatusOnProdOrder: Page "Change Status on Prod. Order";
        NewProductionOrderStatusLocal: Enum "Production Order Status";
        Error: ErrorInfo;
        NewPostingDateLocal: Date;
        NewUpdateUnitCostLocal: Boolean;
        ProgressDialog: Dialog;
        NoOfProductionOrdersToProcess: Integer;
        ProcessedProductionOrdersCounter: Integer;
    begin
        if ProductionOrder.FindSet() then begin
            ChangeStatusOnProdOrder.Set(ProductionOrder);
            if ChangeStatusOnProdOrder.RunModal() <> Action::Yes then
                exit;
            ChangeStatusOnProdOrder.ReturnPostingInfo(NewProductionOrderStatusLocal, NewPostingDateLocal, NewUpdateUnitCostLocal, FinishOrderWithoutOutput);

            NoOfProductionOrdersToProcess := ProductionOrder.Count();
            if NoOfProductionOrdersToProcess > 1 then
                if not Confirm(StrSubstNo(ConfirmationLbl, NoOfProductionOrdersToProcess, ProductionOrder.Status, NewProductionOrderStatusLocal)) then
                    exit;
            ProcessedProductionOrdersCounter := 0;
            ProgressDialog.Open(StrSubstNo(ChangingStatusInfoLbl, NewProductionOrderStatusLocal) + ProcessingProgressTxt);
            repeat
                ProcessedProductionOrdersCounter += 1;
                ProgressDialog.Update(1, ProductionOrder."No.");
                ProgressDialog.Update(2, Round(ProcessedProductionOrdersCounter / NoOfProductionOrdersToProcess * 10000, 1));

                ProdOrderChangeStatusBulk.SetParameters(NewProductionOrderStatusLocal, NewPostingDateLocal, NewUpdateUnitCostLocal, FinishOrderWithoutOutput);
                if not ProdOrderChangeStatusBulk.Run(ProductionOrder) then begin
                    TempErrors.ID := TempErrors.ID + 1;
                    TempErrors.Message := GetLastErrorText();
                    TempErrors.Insert();
                end;
                if System.HasCollectedErrors() then
                    foreach Error in System.GetCollectedErrors() do begin
                        TempErrors.ID := TempErrors.ID + 1;
                        TempErrors.Message := Error.Message;
                        TempErrors.Validate("Record ID", Error.RecordId);
                        TempErrors.Insert();
                    end;

            until ProductionOrder.Next() = 0;
            ClearCollectedErrors();
            if TempErrors.Count > 0 then
                Page.RunModal(Page::"Error Messages", TempErrors);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitItemJnlLineFromProdOrderComp(var ItemJournalLine: Record "Item Journal Line"; ProductionOrder: Record "Production Order"; ProdOrderLine: Record "Prod. Order Line"; ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitItemJnlLineFromProdOrderLine(var ItemJournalLine: Record "Item Journal Line"; ProductionOrder: Record "Production Order"; ProdOrderLine: Record "Prod. Order Line"; ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertProdOrderLine(var ToProdOrderLine: Record "Prod. Order Line"; FromProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTimeAndQuantityOmItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; ProdOrderRoutingLine: Record "Prod. Order Routing Line"; OutputQtyBase: Decimal; OutputQty: Decimal)
    begin
    end;

    local procedure CheckNothingRemainingToPickForProdOrderComp(ProdOrderComponent: Record "Prod. Order Component")
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetFilter(
          "Activity Type", '%1|%2|%3',
          WarehouseActivityLine."Activity Type"::"Invt. Movement", WarehouseActivityLine."Activity Type"::"Invt. Pick",
          WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityLine.SetSourceFilter(
          Database::"Prod. Order Component", ProdOrderComponent.Status.AsInteger(), ProdOrderComponent."Prod. Order No.",
          ProdOrderComponent."Prod. Order Line No.", ProdOrderComponent."Line No.", true);
        WarehouseActivityLine.SetRange("Original Breakbulk", false);
        WarehouseActivityLine.SetRange("Breakbulk No.", 0);
        WarehouseActivityLine.SetFilter("Qty. Outstanding (Base)", '<>%1', 0);
        if not WarehouseActivityLine.IsEmpty() then
            Error(ProdOrderCompRemainToPickErr, ProdOrderComponent."Prod. Order No.");
    end;

    local procedure CheckIfFinishedQtyIsZero(ProdOrder: Record "Production Order"): Boolean
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange(Status, ProdOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrder."No.");
        ProdOrderLine.SetRange("Finished Quantity", 0);
        if not ProdOrderLine.IsEmpty() then
            exit(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransProdOrder(var FromProdOrder: Record "Production Order"; var ToProdOrder: Record "Production Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransProdOrderLines(var FromProdOrder: Record "Production Order"; var ToProdOrder: Record "Production Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransProdOrderComp(var FromProdOrder: Record "Production Order"; var ToProdOrder: Record "Production Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterToProdOrderLineModify(var ToProdOrderLine: Record "Prod. Order Line"; var FromProdOrderLine: Record "Prod. Order Line"; var NewStatus: Option Quote,Planned,"Firm Planned",Released,Finished)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterToProdOrderRtngLineInsert(var ToProdOrderRoutingLine: Record "Prod. Order Routing Line"; var FromProdOrderRoutingLine: Record "Prod. Order Routing Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateQtyToPost(ProdOrderComponent: Record "Prod. Order Component"; var QtyToPost: Decimal; ProdOrder: Record "Production Order"; NewStatus: Enum "Production Order Status")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterChangeStatusOnProdOrder(var ProdOrder: Record "Production Order"; var ToProdOrder: Record "Production Order"; NewStatus: Enum "Production Order Status"; NewPostingDate: Date; NewUpdateUnitCost: Boolean; var SuppressCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateGlobalDim(var ItemJournalLine: Record "Item Journal Line"; ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeChangeStatusOnProdOrder(var ProductionOrder: Record "Production Order"; NewStatus: Option Quote,Planned,"Firm Planned",Released,Finished; var IsHandled: Boolean; NewPostingDate: Date; NewUpdateUnitCost: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBeforeFinishProdOrder(var ProductionOrder: Record "Production Order"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var ChangeStatusOnProdOrderPage: Page "Change Status on Prod. Order"; var ProductionOrder: Record "Production Order"; var IsHandled: Boolean; NewStatus: Enum "Production Order Status"; NewPostingDate: Date; NewUpdateUnitCost: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFlushProdOrder(var ProductionOrder: Record "Production Order"; NewStatus: Enum "Production Order Status"; PostingDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertProdOrderLine(var ToProdOrderLine: Record "Prod. Order Line"; FromProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMakeMultiLevelAdjmt(var ProductionOrder: Record "Production Order"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostFlushItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransProdOrderRtngCmtLn(FromProductionOrder: Record "Production Order"; ToProductionOrder: Record "Production Order"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransProdOrderCmtLine(FromProductionOrder: Record "Production Order"; ToProductionOrder: Record "Production Order"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransProdOrderBOMCmtLine(FromProductionOrder: Record "Production Order"; ToProductionOrder: Record "Production Order"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferLinks(FromProdOrder: Record "Production Order"; ToProdOrder: Record "Production Order"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRoundQtyToPost(ProdOrderComponent: Record "Prod. Order Component"; var QtyToPost: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMatrOrCapConsumpExists(ProdOrderLine: Record "Prod. Order Line"; var EntriesExist: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnChangeProdOrderStatusOnBeforeTransProdOrder(var ProdOrder: Record "Production Order"; NewStatus: Enum "Production Order Status")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckMissingConsumption(var ProductionOrder: Record "Production Order"; var ProdOrderLine: Record "Prod. Order Line"; var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var ShowWarning: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckMissingOutput(var ProductionOrder: Record "Production Order"; var ProdOrderLine: Record "Prod. Order Line"; var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var ShowWarning: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckBeforeFinishProdOrderOnAfterSetProdOrderCompFilters(var ProdOrderComp: Record "Prod. Order Component"; ProductionOrder: Record "Production Order"; var PurchaseLine: Record "Purchase Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckBeforeFinishProdOrderOnAfterCheckProdOrder(var ProdOrder: Record "Production Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromProdOrder(var ToProdOrder: Record "Production Order"; FromProdOrder: Record "Production Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromProdOrderLine(var ToProdOrderLine: Record "Prod. Order Line"; FromProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromProdOrderRoutingLine(var ToProdOrderRoutingLine: Record "Prod. Order Routing Line"; FromProdOrderRoutingLine: Record "Prod. Order Routing Line"; NewPostingDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromProdOrderComp(var ToProdOrderComp: Record "Prod. Order Component"; var FromProdOrderComp: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromProdOrderCapacityNeed(var ToProdOrderCapacityNeed: Record "Prod. Order Capacity Need"; FromProdOrderCapacityNeed: Record "Prod. Order Capacity Need")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFlushProdOrderOnAfterFindProdOrderRtngLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var IsLastOperation: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFlushProdOrderOnAfterPostFlushItemJnlLine(var ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFlushProdOrderOnAfterProdOrderCompSetFilters(ProdOrder: Record "Production Order"; var ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFlushProdOrderOnAfterProdOrderLineLoopIteration(var ProdOrderLine: Record "Prod. Order Line"; NewStatus: Enum "Production Order Status"; PostingDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFlushProdOrderOnBeforeCopyItemTracking(var ItemJournalLine: Record "Item Journal Line"; ProdOrderComponent: Record "Prod. Order Component"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFlushProdOrderProcessProdOrderRtngLineOnAfterCalcOutputQty(ProdOrderLine: Record "Prod. Order Line"; ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var OutputQty: Decimal; var OutputQtyBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFlushProdOrderProcessProdOrderRtngLine(var ProdOrderLine: Record "Prod. Order Line"; var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; PostingDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitItemJnlLineFromProdOrderCompOnAfterInit(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitItemJnlLineFromProdOrderLineOnAfterInit(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransProdOrderCompOnAfterToProdOrderCompInsert(var FromProdOrderComp: Record "Prod. Order Component"; var ToProdOrderComp: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransProdOrderCompOnBeforeToProdOrderCompInsert(var FromProdOrderComp: Record "Prod. Order Component"; var ToProdOrderComp: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransProdOrderLineOnBeforeFinishedInvtAdjmtEntryOrderModify(var InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; FromProdOrderLine: Record "Prod. Order Line"; var ToProdOrderLine: Record "Prod. Order Line"; ToProductionOrder: Record "Production Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransProdOrderLineOnBeforeTransferPOLineToPOLine(FromProdOrderLine: Record "Prod. Order Line"; var ToProdOrderLine: Record "Prod. Order Line"; NewStatus: Enum "Production Order Status")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransProdOrderCapNeedOnBeforeDeleteAll(var ProdOrder: Record "Production Order"; var ProdOrderCapacityNeed: Record "Prod. Order Capacity Need"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetProdOrderCompFilters(var ProdOrderComponent: Record "Prod. Order Component"; ProductionOrder: Record "Production Order");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnErrorIfUnableToClearWIPOnBeforeError(ProdOrderLine: Record "Prod. Order Line"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterChangeStatusFormRun(var ProductionOrder: Record "Production Order"; var ChangeStatusOnProdOrder: Page "Change Status on Prod. Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransProdOrderOnBeforeToProdOrderInsert(var ToProdOrder: Record "Production Order"; FromProdOrder: Record "Production Order"; NewPostingDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowStatusMessage(ProdOrder: Record "Production Order"; ToProdOrder: Record "Production Order"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransProdOrderLineOnAfterDeleteReservEntries(FromProdOrderLine: Record "Prod. Order Line"; var ToProdOrderLine: Record "Prod. Order Line"; var NewStatus: Enum "Production Order Status")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransProdOrderOnAfterStatusIsReleased(var ToProdOrder: Record "Production Order"; FromProdOrder: Record "Production Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransProdOrder(var FromProdOrder: Record "Production Order"; Status: Enum "Production Order Status")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransProdOrderLineOnBeforeFromProdOrderLineLoop(FromProdOrderLine: Record "Prod. Order Line"; var ToProdOrderLine: Record "Prod. Order Line"; NewStatus: Enum "Production Order Status"; var IsHandled: Boolean; ToProductionOrder: Record "Production Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransProdOrderLineOnAfterFromProdOrderLineFindSet(FromProdOrderLine: Record "Prod. Order Line"; var ToProdOrderLine: Record "Prod. Order Line"; NewStatus: Enum "Production Order Status")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnChangeProdOrderStatusOnBeforeDeleteDocReservation(ProdOrder: Record "Production Order"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFlushProdOrderProcessProdOrderRtngLine(ProdOrder: Record "Production Order"; ProdOrderLine: Record "Prod. Order Line"; ProdOrderRtngLine: Record "Prod. Order Routing Line"; NewStatus: Option Simulated,Planned,"Firm Planned",Released,Finished; PostingDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRoundQtyToPost(ProdOrderComp: Record "Prod. Order Component"; QtyToPost: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckBeforeFinishProdOrderOnBeforeFindSet(var ProdOrderLine: Record "Prod. Order Line"; var ProdOrderRtngLine: Record "Prod. Order Routing Line"; var ShowWarning: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferLinksOnBeforeCopyLinks(var FromProductionOrder: Record "Production Order"; var ToProductionOrder: Record "Production Order"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransProdOrderLineOnAfterFromProdOrderLineSetFilters(var FromProdOrderLine: Record "Prod. Order Line"; var FromProductionOrder: Record "Production Order"; NewUpdateUnitCost: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransProdOrderComp(FromProdOrder: Record "Production Order"; var ToProdOrder: Record "Production Order"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnErrorIfUnableToClearWIPOnAfterProdOrderLineSetFilters(ProductionOrder: Record "Production Order"; var ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferReopenProdOrderLine(ProdOrderLine: Record "Prod. Order Line"; FromProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferRelatedTablesToReleasedProdOrder(ProductionOrder: Record "Production Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProcessProdOrderLineForReopenOnBeforeDeleteUpdateProdOrderLine(ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferReopenProdOrder(ProductionOrder: Record "Production Order"; FromProductionOrder: Record "Production Order")
    begin
    end;
}

