// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Purchases.Comment;
using Microsoft.Utilities;
using System.Automation;

report 491 "Delete Invd Blnkt Purch Orders"
{
    AccessByPermission = TableData "Purchase Header" = RD;
    ApplicationArea = Suite;
    Caption = 'Delete Invoiced Blanket Purchase Orders';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("Purchase Header"; "Purchase Header")
        {
            DataItemTableView = sorting("Document Type", "No.") where("Document Type" = const("Blanket Order"));
            RequestFilterFields = "No.", "Buy-from Vendor No.", "Pay-to Vendor No.";
            RequestFilterHeading = 'Blanket Purchase Order';

            trigger OnAfterGetRecord()
            var
                PurchaseBlanketOrderLine: Record "Purchase Line";
                PurchaseLineFromBlanketOrder: Record "Purchase Line";
                PurchCommentLine: Record "Purch. Comment Line";
                ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                ArchiveManagement: Codeunit ArchiveManagement;
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforePurchaseHeaderOnAfterGetRecord("Purchase Header", IsHandled, ProgressDialog);
                if IsHandled then
                    CurrReport.Skip();

                if GuiAllowed() then
                    ProgressDialog.Update(1, "No.");

                PurchaseBlanketOrderLine.SetRange("Document Type", "Document Type");
                PurchaseBlanketOrderLine.SetRange("Document No.", "No.");
                PurchaseBlanketOrderLine.SetFilter("Quantity Invoiced", '<>0');
                if PurchaseBlanketOrderLine.FindFirst() then begin
                    PurchaseBlanketOrderLine.SetRange("Quantity Invoiced");
                    PurchaseBlanketOrderLine.SetFilter("Outstanding Quantity", '<>0');
                    OnAfterSetPurchLineFilters(PurchaseBlanketOrderLine);
                    if not PurchaseBlanketOrderLine.FindFirst() then begin
                        PurchaseBlanketOrderLine.SetRange("Outstanding Quantity");
                        PurchaseBlanketOrderLine.SetFilter("Qty. Rcd. Not Invoiced", '<>0');
                        if not PurchaseBlanketOrderLine.FindFirst() then begin
                            PurchaseBlanketOrderLine.LockTable();
                            if not PurchaseBlanketOrderLine.FindFirst() then begin
                                PurchaseBlanketOrderLine.SetRange("Qty. Rcd. Not Invoiced");
                                PurchaseLineFromBlanketOrder.SetRange("Blanket Order No.", "No.");
                                if PurchaseLineFromBlanketOrder.IsEmpty() then begin
                                    ArchiveManagement.AutoArchivePurchDocument("Purchase Header");

                                    OnBeforeDeletePurchLines(PurchaseBlanketOrderLine);
                                    PurchaseBlanketOrderLine.DeleteAll();
                                    OnAfterDeletePurchLines(PurchaseBlanketOrderLine);

                                    PurchCommentLine.SetRange("Document Type", "Document Type");
                                    PurchCommentLine.SetRange("No.", "No.");
                                    PurchCommentLine.DeleteAll();

                                    ApprovalsMgmt.DeleteApprovalEntries(RecordId);

                                    OnBeforeDeletePurchaseHeader("Purchase Header");
                                    Delete();
                                    OnAfterDeletePurchaseHeader("Purchase Header");

                                    Commit();
                                end;
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

    var
        ProgressDialog: Dialog;
        ProcessingProgressTxt: Label 'Processing blanket purchase orders #1##########', Comment = '%1 - Blanket Purchase Order No.';

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetPurchLineFilters(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeletePurchaseHeader(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeletePurchLines(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeletePurchaseHeader(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeletePurchLines(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchaseHeaderOnAfterGetRecord(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean; var ProgressDialog: Dialog)
    begin
    end;
}

