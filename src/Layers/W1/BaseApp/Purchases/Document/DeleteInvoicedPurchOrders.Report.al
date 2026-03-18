// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Purchases.Comment;
using Microsoft.Purchases.History;
using Microsoft.Utilities;
using Microsoft.Warehouse.Request;
using System.Automation;

report 499 "Delete Invoiced Purch. Orders"
{
    AccessByPermission = TableData "Purchase Header" = RD;
    ApplicationArea = Suite;
    Caption = 'Delete Invoiced Purchase Orders';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("Purchase Header"; "Purchase Header")
        {
            DataItemTableView = sorting("Document Type", "No.") where("Document Type" = const(Order));
            RequestFilterFields = "No.", "Buy-from Vendor No.", "Pay-to Vendor No.";
            RequestFilterHeading = 'Purchase Order';

            trigger OnAfterGetRecord()
            var
                PurchaseOrderLine: Record "Purchase Line";
                PurchRcptHeader: Record "Purch. Rcpt. Header";
                PurchInvHeader: Record "Purch. Inv. Header";
                PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
                ReturnShipmentHeader: Record "Return Shipment Header";
                PrepaymentPurchInvHeader: Record "Purch. Inv. Header";
                PrepaymentPurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
                PurchCommentLine: Record "Purch. Comment Line";
                ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
                WarehouseRequest: Record "Warehouse Request";
                PurchLineReserve: Codeunit "Purch. Line-Reserve";
                ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                ArchiveManagement: Codeunit ArchiveManagement;
                PostPurchDelete: Codeunit "PostPurch-Delete";
                IsHandled: Boolean;
                ItemChargeComplete: Boolean;
                ShouldDeleteLinks: Boolean;
                SuppressCommit: Boolean;
            begin
                IsHandled := false;
                OnBeforePurchaseHeaderOnAfterGetRecord("Purchase Header", IsHandled);
                if IsHandled then
                    CurrReport.Skip();

                if GuiAllowed() then
                    Window.Update(1, "No.");

                ItemChargeAssignmentPurch.SetRange("Document Type", "Document Type");
                ItemChargeAssignmentPurch.SetRange("Document No.", "No.");

                // Continue only if there are invoiced lines in the purchase document
                PurchaseOrderLine.SetRange("Document Type", "Document Type");
                PurchaseOrderLine.SetRange("Document No.", "No.");
                PurchaseOrderLine.SetFilter("Quantity Invoiced", '<>0');
                OnAfterGetRecordPurchaseHeaderOnBeforeCheckInvoicedPurchaseLineIsEmpty(PurchaseOrderLine, "Purchase Header");
                if PurchaseOrderLine.IsEmpty() then
                    exit;

                // Continue only if there are no outstanding quantity to receive
                PurchaseOrderLine.SetRange("Quantity Invoiced");
                PurchaseOrderLine.SetFilter("Outstanding Quantity", '<>0');
                OnAfterSetPurchLineFilters(PurchaseOrderLine);
                if not PurchaseOrderLine.IsEmpty() then
                    exit;

                // Continue only if all lines are received and invoiced
                PurchaseOrderLine.SetRange("Outstanding Quantity");
                PurchaseOrderLine.SetFilter("Qty. Rcd. Not Invoiced", '<>0');
                if not PurchaseOrderLine.IsEmpty() then
                    exit;

                // Find if there are any uninvoiced item charges
                PurchaseOrderLine.SetRange("Qty. Rcd. Not Invoiced");
                ItemChargeComplete := true;
                PurchaseOrderLine.SetRange(Type, PurchaseOrderLine.Type::"Charge (Item)");
                if PurchaseOrderLine.FindSet() then
                    repeat
                        PurchaseOrderLine.CalcFields("Qty. Assigned");
                        if (PurchaseOrderLine."Qty. Assigned" <> PurchaseOrderLine."Quantity Invoiced") and
                           not IsPostedUnassignedItemChargeWithZeroAmount(PurchaseOrderLine)
                        then
                            ItemChargeComplete := false;
                    until (PurchaseOrderLine.Next() = 0) or not ItemChargeComplete;

                PurchaseOrderLine.SetRange(Type);
                if not ItemChargeComplete then
                    exit;

                // The purchase order can be deleted. Archive and delete the document
                // Archive the purchase document
                IsHandled := false;
                OnBeforeAutoArchivePurchDocument("Purchase Header", IsHandled);
                if not IsHandled then
                    ArchiveManagement.AutoArchivePurchDocument("Purchase Header");

                // Delete lines and then the header
                PurchaseOrderLine.LockTable();
                if PurchaseOrderLine.Find('-') then
                    repeat
                        if PurchaseOrderLine.Type = PurchaseOrderLine.Type::"Charge (Item)" then begin
                            ItemChargeAssignmentPurch.SetRange("Document Line No.", PurchaseOrderLine."Line No.");
                            ItemChargeAssignmentPurch.DeleteAll();
                        end;
                        ShouldDeleteLinks := PurchaseOrderLine.HasLinks();
                        OnPurchaseHeaderOnAfterGetRecordOnAfterCalcShouldDeleteLinks(PurchaseOrderLine, ShouldDeleteLinks);
                        if ShouldDeleteLinks then
                            PurchaseOrderLine.DeleteLinks();

                        OnBeforePurchLineDelete(PurchaseOrderLine);
                        PurchaseOrderLine.Delete();
                        OnAfterPurchLineDelete(PurchaseOrderLine);
                    until PurchaseOrderLine.Next() = 0;

                PostPurchDelete.DeleteHeader(
                  "Purchase Header", PurchRcptHeader, PurchInvHeader, PurchCrMemoHdr,
                  ReturnShipmentHeader, PrepaymentPurchInvHeader, PrepaymentPurchCrMemoHdr);

                PurchLineReserve.DeleteInvoiceSpecFromHeader("Purchase Header");

                PurchCommentLine.SetRange("Document Type", "Document Type");
                PurchCommentLine.SetRange("No.", "No.");
                PurchCommentLine.DeleteAll();

                WarehouseRequest.SetRange("Source Type", Database::"Purchase Line");
                WarehouseRequest.SetRange("Source Subtype", "Document Type");
                WarehouseRequest.SetRange("Source No.", "No.");
                if not WarehouseRequest.IsEmpty() then
                    WarehouseRequest.DeleteAll(true);

                ApprovalsMgmt.DeleteApprovalEntries(RecordId);

                IsHandled := false;
                OnPurchaseHeaderOnAfterGetRecordOnBeforeDeleteLinks("Purchase Header", IsHandled);
                if not IsHandled then
                    if HasLinks() then
                        DeleteLinks();

                IsHandled := false;
                OnBeforeDeletePurchaseHeader("Purchase Header", IsHandled);
                if not IsHandled then
                    Delete();
                OnAfterDeletePurchaseHeader("Purchase Header", SuppressCommit);

                if not SuppressCommit then
                    Commit();
            end;

            trigger OnPreDataItem()
            begin
                if GuiAllowed() then
                    Window.Open(ProcessingProgressTxt);
            end;

            trigger OnPostDataItem()
            begin
                if GuiAllowed() then
                    Window.Close();
            end;
        }
    }

    var
        ProcessingProgressTxt: Label 'Processing purchase orders #1##########', Comment = '%1 - Purchase Order No.';

    protected var
        Window: Dialog;

    local procedure IsPostedUnassignedItemChargeWithZeroAmount(PurchaseLine: Record "Purchase Line"): Boolean
    begin
        if (PurchaseLine.Type = PurchaseLine.Type::"Charge (Item)") and
           (PurchaseLine.Quantity = PurchaseLine."Quantity Invoiced") and
           (PurchaseLine.Amount = 0)
        then begin
            PurchaseLine.CalcFields("Qty. Assigned");
            if PurchaseLine."Qty. Assigned" = 0 then
                exit(true);
        end;

        exit(false);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterSetPurchLineFilters(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchLineDelete(var PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterDeletePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; var SuppressCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAutoArchivePurchDocument(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchLineDelete(var PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeDeletePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchaseHeaderOnAfterGetRecord(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPurchaseHeaderOnAfterGetRecordOnAfterCalcShouldDeleteLinks(var PurchaseLine: Record "Purchase Line"; var ShouldDeleteLinks: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPurchaseHeaderOnAfterGetRecordOnBeforeDeleteLinks(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterGetRecordPurchaseHeaderOnBeforeCheckInvoicedPurchaseLineIsEmpty(var PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header")
    begin
    end;
}

