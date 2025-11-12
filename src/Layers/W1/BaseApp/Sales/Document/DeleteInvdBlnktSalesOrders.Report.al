// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Assembly.Document;
using Microsoft.Sales.Comment;
using Microsoft.Utilities;
using System.Automation;
using System.Telemetry;

report 291 "Delete Invd Blnkt Sales Orders"
{
    AccessByPermission = TableData "Sales Header" = RD;
    ApplicationArea = Suite;
    Caption = 'Delete Invoiced Blanket Sales Orders';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("Sales Header"; "Sales Header")
        {
            DataItemTableView = sorting("Document Type", "No.") where("Document Type" = const("Blanket Order"));
            RequestFilterFields = "No.", "Sell-to Customer No.", "Bill-to Customer No.";
            RequestFilterHeading = 'Blanket Sales Order';

            trigger OnAfterGetRecord()
            var
                SalesBlanketOrderLine: Record "Sales Line";
                SalesLineFromBlanketOrder: Record "Sales Line";
                SalesCommentLine: Record "Sales Comment Line";
                AssembleToOrderLink: Record "Assemble-to-Order Link";
                ArchiveManagement: Codeunit ArchiveManagement;
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnSalesHeaderOnBeforeOnAfterGetRecord("Sales Header", IsHandled);
                if IsHandled then
                    CurrReport.Skip();

                if GuiAllowed() then
                    ProgressDialog.Update(1, "No.");

                SalesBlanketOrderLine.SetRange("Document Type", "Document Type");
                SalesBlanketOrderLine.SetRange("Document No.", "No.");
                SalesBlanketOrderLine.SetFilter("Quantity Invoiced", '<>0');
                if SalesBlanketOrderLine.FindFirst() then begin
                    SalesBlanketOrderLine.SetRange("Quantity Invoiced");
                    SalesBlanketOrderLine.SetFilter("Outstanding Quantity", '<>0');
                    OnAfterSetSalesLineFilters(SalesBlanketOrderLine);
                    if not SalesBlanketOrderLine.FindFirst() then begin
                        SalesBlanketOrderLine.SetRange("Outstanding Quantity");
                        SalesBlanketOrderLine.SetFilter("Qty. Shipped Not Invoiced", '<>0');
                        if not SalesBlanketOrderLine.FindFirst() then begin
                            SalesBlanketOrderLine.LockTable();
                            if not SalesBlanketOrderLine.FindFirst() then begin
                                SalesBlanketOrderLine.SetRange("Qty. Shipped Not Invoiced");
                                SalesLineFromBlanketOrder.SetRange("Blanket Order No.", "No.");
                                if SalesLineFromBlanketOrder.IsEmpty() then begin
                                    ArchiveManagement.AutoArchiveSalesDocument("Sales Header");
                                    SalesBlanketOrderLine.SetFilter("Qty. to Assemble to Order", '<>0');
                                    if SalesBlanketOrderLine.FindSet() then
                                        repeat
                                            AssembleToOrderLink.DeleteAsmFromSalesLine(SalesBlanketOrderLine);
                                        until SalesBlanketOrderLine.Next() = 0;
                                    SalesBlanketOrderLine.SetRange("Qty. to Assemble to Order");
                                    OnBeforeDeleteSalesLines(SalesBlanketOrderLine);
                                    SalesBlanketOrderLine.DeleteAll();

                                    SalesCommentLine.SetRange("Document Type", "Document Type");
                                    SalesCommentLine.SetRange("No.", "No.");
                                    SalesCommentLine.DeleteAll();

                                    DeleteApprovalEntries("Sales Header");

                                    OnBeforeDeleteSalesHeader("Sales Header");
                                    Delete();

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

    trigger OnPostReport()
    var
        AuditLog: Codeunit "Audit Log";
    begin
        AuditLog.LogAuditMessage(StrSubstNo(DeletedInvoicedBlanketSalesOrdersLbl, UserSecurityId(), CompanyName()), SecurityOperationResult::Success, AuditCategory::ApplicationManagement, 3, 0);
    end;

    var
        ProgressDialog: Dialog;
        ProcessingProgressTxt: Label 'Processing blanket sales orders #1##########', Comment = '%1 - Blanket Sales Order No.';
        DeletedInvoicedBlanketSalesOrdersLbl: Label 'Invoiced blanket sales orders deleted by UserSecurityId %1 for company %2.', Comment = '%1 - User Security ID, %2 - Company name', Locked = true;

    local procedure DeleteApprovalEntries(SalesHeader: Record "Sales Header")
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeleteApprovalEntries(SalesHeader, IsHandled);
        if IsHandled then
            exit;

        ApprovalsMgmt.DeleteApprovalEntries(SalesHeader.RecordId);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetSalesLineFilters(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteSalesHeader(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteSalesLines(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteApprovalEntries(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSalesHeaderOnBeforeOnAfterGetRecord(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;
}

