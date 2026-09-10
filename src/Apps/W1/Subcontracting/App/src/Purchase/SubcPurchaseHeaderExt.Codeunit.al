// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Transfer;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.Utilities;

codeunit 20533 "Subc. Purchase Header Ext"
{
    var
#if not CLEAN29
#pragma warning disable AL0432
        SubcFeatureFlagHandler: Codeunit "Subc. Feature Flag Handler";
#pragma warning restore AL0432
#endif
        SubcSynchronizeManagement: Codeunit "Subc. Synchronize Management";
        SubcTransferManagement: Codeunit "Subc. Transfer Management";

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", OnAfterCopyBuyFromVendorFieldsFromVendor, '', false, false)]
    local procedure OnAfterCopyBuyFromVendorFieldsFromVendor(var PurchaseHeader: Record "Purchase Header"; Vendor: Record Vendor; xPurchaseHeader: Record "Purchase Header")
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        PurchaseHeader."Subc. Location Code" := Vendor."Subc. Location Code";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", OnAfterValidateEvent, "Buy-from Vendor No.", false, false)]
    local procedure OnAfterValidateEventBuyFromVendorNo(var Rec: Record "Purchase Header"; var xRec: Record "Purchase Header")
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        SubcSynchronizeManagement.DeleteEnhancedDocumentsByChangeOfVendorNo(Rec, xRec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", OnBeforeDeleteEvent, '', false, false)]
    local procedure CheckTransferOrderOnBeforeDeleteEvent(var Rec: Record "Purchase Header"; RunTrigger: Boolean)
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        if Rec.IsTemporary() then
            exit;
        if not RunTrigger then
            exit;

        Rec.CalcFields("Subc. Order");
        if not Rec."Subc. Order" then
            exit;

        SubcSynchronizeManagement.CheckTransferOrderExistsForPurchaseHeader(Rec);
        SubcTransferManagement.CheckStockAtSubcLocationForPurchHeader(Rec);
    end;

    internal procedure CreateCoveredTransferErrorInfo(PurchaseHeader: Record "Purchase Header") TransferOrderErrorInfo: ErrorInfo
    var
        TransferHeader: Record "Transfer Header";
        NoNewTransferLinesTitleLbl: Label 'There are no new subcontracting transfer lines to create';
        CoveredTransferDemandErr: Label 'The components and WIP for this subcontracting order are already covered by open transfer orders, quantities in transit, or quantities transferred to the subcontractor.';
        ShowOpenTransferOrdersLbl: Label 'Show open transfer orders';
    begin
        TransferOrderErrorInfo.Title := NoNewTransferLinesTitleLbl;
        TransferOrderErrorInfo.Message := CoveredTransferDemandErr;
        TransferOrderErrorInfo.RecordId := PurchaseHeader.RecordId();
        TransferHeader.SetRange("Subcontr. Purch. Order No.", PurchaseHeader."No.");
        TransferHeader.SetRange("Subc. Return Order", false);
        if not TransferHeader.IsEmpty() then
            TransferOrderErrorInfo.AddAction(
                ShowOpenTransferOrdersLbl, Codeunit::"Subc. Purchase Header Ext", 'ShowOutboundTransferOrdersForPurchHeader');
    end;

    internal procedure ShowOutboundTransferOrdersForPurchHeader(TransferOrderErrorInfo: ErrorInfo)
    var
        PurchaseHeader: Record "Purchase Header";
        SubcPurchFactboxMgmt: Codeunit "Subc. Purch. Factbox Mgmt.";
    begin
        PurchaseHeader.Get(TransferOrderErrorInfo.RecordId);
        SubcPurchFactboxMgmt.ShowTransferOrdersFromPurchaseOrder(PurchaseHeader, false);
    end;

    internal procedure ShowTransferOrdersForPurchHeader(TransferOrderErrorInfo: ErrorInfo)
    var
        PurchaseHeader: Record "Purchase Header";
        TransferHeader: Record "Transfer Header";
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        PurchaseHeader.Get(TransferOrderErrorInfo.RecordId);
        TransferHeader.SetRange("Subcontr. Purch. Order No.", PurchaseHeader."No.");
        if TransferHeader.Count() = 1 then begin
            TransferHeader.FindFirst();
            Page.Run(Page::"Transfer Order", TransferHeader);
        end else
            Page.Run(Page::"Transfer Orders", TransferHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Document Mgt.", OnAfterCopyPurchHeaderDone, '', false, false)]
    local procedure ClearSubcLocationCodeOnAfterCopyPurchHeaderDone(var ToPurchaseHeader: Record "Purchase Header")
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        ToPurchaseHeader."Subc. Location Code" := '';
    end;
}
