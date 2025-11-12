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
using System.Telemetry;

report 6661 "Delete Invd Purch. Ret. Orders"
{
    AccessByPermission = TableData "Purchase Header" = RD;
    ApplicationArea = PurchReturnOrder;
    Caption = 'Delete Invoiced Purchase Return Orders';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("Purchase Header"; "Purchase Header")
        {
            DataItemTableView = sorting("Document Type", "No.") where("Document Type" = const("Return Order"));
            RequestFilterFields = "No.", "Buy-from Vendor No.", "Pay-to Vendor No.";
            RequestFilterHeading = 'Purchase Return Order';

            trigger OnAfterGetRecord()
            var
                PurchaseReturnOrderLine: Record "Purchase Line";
                PurchRcptHeader: Record "Purch. Rcpt. Header";
                PurchInvHeader: Record "Purch. Inv. Header";
                PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
                ReturnShipmentHeader: Record "Return Shipment Header";
                PrepaymentPurchInvHeader: Record "Purch. Inv. Header";
                PrepaymentPurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
                PurchCommentLine: Record "Purch. Comment Line";
                ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
                WhseRequest: Record "Warehouse Request";
                PurchLineReserve: Codeunit "Purch. Line-Reserve";
                ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                ArchiveManagement: Codeunit ArchiveManagement;
                PostPurchDelete: Codeunit "PostPurch-Delete";
                AllLinesDeleted: Boolean;
                IsHandled: Boolean;
                ShouldDeleteLinks: Boolean;
            begin
                IsHandled := false;
                OnBeforePurchaseHeaderOnAfterGetRecord("Purchase Header", IsHandled, ProgressDialog);
                if IsHandled then
                    CurrReport.Skip();

                if GuiAllowed() then
                    ProgressDialog.Update(1, "No.");

                AllLinesDeleted := true;
                ItemChargeAssignmentPurch.SetRange("Document Type", "Document Type");
                ItemChargeAssignmentPurch.SetRange("Document No.", "No.");
                PurchaseReturnOrderLine.SetRange("Document Type", "Document Type");
                PurchaseReturnOrderLine.SetRange("Document No.", "No.");
                PurchaseReturnOrderLine.SetFilter("Quantity Invoiced", '<>0');
                if PurchaseReturnOrderLine.Find('-') then begin
                    PurchaseReturnOrderLine.SetRange("Quantity Invoiced");
                    PurchaseReturnOrderLine.SetFilter("Outstanding Quantity", '<>0');
                    OnAfterSetPurchLineFilters(PurchaseReturnOrderLine);
                    if not PurchaseReturnOrderLine.Find('-') then begin
                        PurchaseReturnOrderLine.SetRange("Outstanding Quantity");
                        PurchaseReturnOrderLine.SetFilter("Return Qty. Shipped Not Invd.", '<>0');
                        if not PurchaseReturnOrderLine.Find('-') then begin
                            PurchaseReturnOrderLine.LockTable();
                            if not PurchaseReturnOrderLine.Find('-') then begin
                                PurchaseReturnOrderLine.SetRange("Return Qty. Shipped Not Invd.");
                                ArchiveManagement.AutoArchivePurchDocument("Purchase Header");
                                if PurchaseReturnOrderLine.Find('-') then
                                    repeat
                                        PurchaseReturnOrderLine.CalcFields("Qty. Assigned");
                                        if ((PurchaseReturnOrderLine."Qty. Assigned" = PurchaseReturnOrderLine."Quantity Invoiced") and
                                            (PurchaseReturnOrderLine."Qty. Assigned" <> 0)) or
                                           (PurchaseReturnOrderLine.Type <> PurchaseReturnOrderLine.Type::"Charge (Item)")
                                        then begin
                                            if PurchaseReturnOrderLine.Type = PurchaseReturnOrderLine.Type::"Charge (Item)" then begin
                                                ItemChargeAssignmentPurch.SetRange("Document Line No.", PurchaseReturnOrderLine."Line No.");
                                                ItemChargeAssignmentPurch.DeleteAll();
                                            end;
                                            ShouldDeleteLinks := PurchaseReturnOrderLine.HasLinks();
                                            OnPurchaseHeaderOnAfterGetRecordOnAfterCalcShouldDeleteLinks(PurchaseReturnOrderLine, ShouldDeleteLinks);
                                            if ShouldDeleteLinks then
                                                PurchaseReturnOrderLine.DeleteLinks();
                                            OnBeforePurchLineDelete(PurchaseReturnOrderLine);
                                            PurchaseReturnOrderLine.Delete();
                                            OnAfterPurchLineDelete(PurchaseReturnOrderLine);
                                        end else
                                            AllLinesDeleted := false;
                                    until PurchaseReturnOrderLine.Next() = 0;

                                if AllLinesDeleted then begin
                                    PostPurchDelete.DeleteHeader(
                                      "Purchase Header", PurchRcptHeader, PurchInvHeader, PurchCrMemoHdr,
                                      ReturnShipmentHeader, PrepaymentPurchInvHeader, PrepaymentPurchCrMemoHdr);
                                    PurchLineReserve.DeleteInvoiceSpecFromHeader("Purchase Header");

                                    PurchCommentLine.SetRange("Document Type", "Document Type");
                                    PurchCommentLine.SetRange("No.", "No.");
                                    PurchCommentLine.DeleteAll();

                                    WhseRequest.SetRange("Source Type", Database::"Purchase Line");
                                    WhseRequest.SetRange("Source Subtype", "Document Type");
                                    WhseRequest.SetRange("Source No.", "No.");
                                    if not WhseRequest.IsEmpty() then
                                        WhseRequest.DeleteAll(true);

                                    ApprovalsMgmt.DeleteApprovalEntries(RecordId);

                                    OnBeforeDeletePurchaseHeader("Purchase Header");
                                    Delete();
                                    OnAfterDeletePurchaseHeader("Purchase Header");
                                end;
                                IsHandled := false;
                                OnPurchaseHeaderAfterGetRecordOnBeforeCommit(IsHandled);
                                if not IsHandled then
                                    Commit();
                            end;
                        end;
                    end;
                end;
            end;

            trigger OnPreDataItem()
            begin
                if GuiAllowed() then
                    ProgressDialog.Open(ProcessingProgressTxt);
            end;

            trigger OnPostDataItem()
            begin
                if GuiAllowed() then
                    ProgressDialog.Close();
            end;
        }
    }

    trigger OnPostReport()
    var
        AuditLog: Codeunit "Audit Log";
    begin
        AuditLog.LogAuditMessage(StrSubstNo(DeletedInvoicedPurchaseReturnOrdersLbl, UserSecurityId(), CompanyName()), SecurityOperationResult::Success, AuditCategory::ApplicationManagement, 3, 0);
    end;

    var
        ProgressDialog: Dialog;
        ProcessingProgressTxt: Label 'Processing purchase return orders #1##########', Comment = '%1 - Purchase Return Order No.';
        DeletedInvoicedPurchaseReturnOrdersLbl: Label 'Invoiced purchase return orders deleted by UserSecurityId %1 for company %2.', Comment = '%1 - User Security ID, %2 - Company name', Locked = true;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetPurchLineFilters(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeletePurchaseHeader(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchLineDelete(var PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchLineDelete(var PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeDeletePurchaseHeader(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchaseHeaderOnAfterGetRecord(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean; var ProgressDialog: Dialog)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPurchaseHeaderAfterGetRecordOnBeforeCommit(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPurchaseHeaderOnAfterGetRecordOnAfterCalcShouldDeleteLinks(var PurchaseLine: Record "Purchase Line"; var ShouldDeleteLinks: Boolean)
    begin
    end;
}

