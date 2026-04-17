// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;

codeunit 99001549 "Subc. Change Prod.Order Status"
{

    [EventSubscriber(ObjectType::Page, Page::"Change Status on Prod. Order", OnAfterSet, '', false, false)]
    local procedure "Change Status on Prod. Order_OnAfterSet"(var Sender: Page "Change Status on Prod. Order"; ProdOrder: Record "Production Order"; var PostingDate: Date; var ReqUpdUnitCost: Boolean; var ProductionOrderStatus: Record "Production Order"; var FirmPlannedStatusEditable: Boolean; var ReleasedStatusEditable: Boolean; var FinishedStatusEditable: Boolean)
    begin
        Sender.SubcSetOrder(ProdOrder);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Prod. Order Status Management", OnRunOnAfterChangeStatusFormRun, '', false, false)]
    local procedure ChangeProdOrderStatusOnRunOnAfterChangeStatusFormRun(var ProductionOrder: Record "Production Order"; var ChangeStatusOnProdOrder: Page "Change Status on Prod. Order")
    var
        SubcTransferWIPPosting: Codeunit "Subc. Transfer WIP Posting";
        FinishOrderWithoutOutput: Boolean;
        NewUpdateUnitCost: Boolean;
        NewPostingDate: Date;
        NewStatus: Enum "Production Order Status";
    begin
        if ChangeStatusOnProdOrder.ReturnSubWIPQuantityCleanUp() then begin
            ChangeStatusOnProdOrder.ReturnPostingInfo(NewStatus, NewPostingDate, NewUpdateUnitCost, FinishOrderWithoutOutput);
            SubcTransferWIPPosting.CreateAdjustmentWIPEntriesOnFinishProdOrder(ChangeStatusOnProdOrder.SubcGetOrder(), NewPostingDate);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Prod. Order Status Management", OnAfterTransferRelatedTablesToReleasedProdOrder, '', false, false)]
    local procedure ReopenWIPEntriesOnAfterTransferRelatedTablesToReleasedProdOrder(ProductionOrder: Record "Production Order")
    begin
        ReopenWIPEntries(ProductionOrder);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Prod. Order Status Management", OnBeforeChangeStatusOnProdOrder, '', false, false)]
    local procedure CheckForOpenTransferOrdersOnBeforeChangeStatusOnProdOrder(var ProductionOrder: Record "Production Order"; NewStatus: Option; var IsHandled: Boolean; NewPostingDate: Date; NewUpdateUnitCost: Boolean)
    begin
        CheckForOpenTransferOrders(ProductionOrder);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Prod. Order Status Management", OnAfterChangeStatusOnProdOrder, '', false, false)]
    local procedure "Prod. Order Status Management_OnAfterChangeStatusOnProdOrder"(var ProdOrder: Record "Production Order"; var ToProdOrder: Record "Production Order"; NewStatus: Enum "Production Order Status"; NewPostingDate: Date; NewUpdateUnitCost: Boolean; var SuppressCommit: Boolean; xProductionOrder: Record "Production Order")
    begin
        UpdateWIPLedgerEntryProdOrderRelation(xProductionOrder, ToProdOrder, NewStatus);
    end;

    local procedure ReopenWIPEntries(ProductionOrder: Record "Production Order")
    var
        SubcontractorWIPLedgerEntry: Record "Subcontractor WIP Ledger Entry";
    begin
        SubcontractorWIPLedgerEntry.SetCurrentKey("Prod. Order No.", "Prod. Order Status", "Prod. Order Line No.", "Routing Reference No.", "Routing No.", "Operation No.", "Location Code");
        SubcontractorWIPLedgerEntry.SetRange("Prod. Order No.", ProductionOrder."No.");
        if not SubcontractorWIPLedgerEntry.IsEmpty() then
            SubcontractorWIPLedgerEntry.ModifyAll("Prod. Order Status", "Production Order Status"::Released);
    end;

    local procedure CheckForOpenTransferOrders(var ProductionOrder: Record "Production Order")
    var
        TransferLine: Record "Transfer Line";
        TransferOrderExistsErr: Label 'There is an open transfer order (Transfer Order No.: %1) related to this production order. Please close the transfer order before finishing the production order.',
Comment = '%1=Transfer Header No';
    begin
        TransferLine.SetLoadFields("Document No.");
        TransferLine.SetCurrentKey("Prod. Order No.", "Routing No.", "Routing Reference No.", "Operation No.", "Subcontr. Purch. Order No.");
        TransferLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        TransferLine.SetRange("Derived From Line No.", 0);
        if TransferLine.FindFirst() then
            Error(TransferOrderExistsErr, TransferLine."Document No.");
    end;

    local procedure UpdateWIPLedgerEntryProdOrderRelation(xProductionOrder: Record "Production Order"; var ToProdOrder: Record "Production Order"; NewStatus: Enum Microsoft.Manufacturing.Document."Production Order Status")
    var
        SubcontractorWIPLedgerEntry: Record "Subcontractor WIP Ledger Entry";
    begin
        SubcontractorWIPLedgerEntry.SetProductionOrderFilter(xProductionOrder, true);
        SubcontractorWIPLedgerEntry.ModifyAll("Prod. Order Status", NewStatus);
        SubcontractorWIPLedgerEntry.SetRange("Prod. Order Status", NewStatus);
        SubcontractorWIPLedgerEntry.ModifyAll("Prod. Order No.", ToProdOrder."No.");
    end;
}