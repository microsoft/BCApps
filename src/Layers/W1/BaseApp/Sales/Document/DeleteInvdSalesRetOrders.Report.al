// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Sales.Comment;
using Microsoft.Sales.History;
using Microsoft.Utilities;
using Microsoft.Warehouse.Request;
using System.Automation;

report 6651 "Delete Invd Sales Ret. Orders"
{
    AccessByPermission = TableData "Sales Header" = RD;
    ApplicationArea = SalesReturnOrder;
    Caption = 'Delete Invoiced Sales Return Orders';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("Sales Header"; "Sales Header")
        {
            DataItemTableView = sorting("Document Type", "No.") where("Document Type" = const("Return Order"));
            RequestFilterFields = "No.", "Sell-to Customer No.", "Bill-to Customer No.";
            RequestFilterHeading = 'Sales Return Order';

            trigger OnAfterGetRecord()
            var
                SalesReturnOrderLine: Record "Sales Line";
                SalesShipmentHeader: Record "Sales Shipment Header";
                SalesInvoiceHeader: Record "Sales Invoice Header";
                SalesCrMemoHeader: Record "Sales Cr.Memo Header";
                ReturnReceiptHeader: Record "Return Receipt Header";
                PrepaymentSalesInvoiceHeader: Record "Sales Invoice Header";
                PrepaymentSalesCrMemoHeader: Record "Sales Cr.Memo Header";
                SalesCommentLine: Record "Sales Comment Line";
                ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
                WarehouseRequest: Record "Warehouse Request";
                SalesLineReserve: Codeunit "Sales Line-Reserve";
                ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                ArchiveManagement: Codeunit ArchiveManagement;
                PostSalesDelete: Codeunit "PostSales-Delete";
                AllLinesDeleted: Boolean;
                IsHandled: Boolean;
                SuppressCommit: Boolean;
            begin
                IsHandled := false;
                OnSalesHeaderOnBeforeOnAfterGetRecord("Sales Header", IsHandled, ProgressDialog);
                if IsHandled then
                    exit;

                if GuiAllowed() then
                    ProgressDialog.Update(1, "No.");

                AllLinesDeleted := true;
                ItemChargeAssignmentSales.SetRange("Document Type", "Document Type");
                ItemChargeAssignmentSales.SetRange("Document No.", "No.");
                SalesReturnOrderLine.SetRange("Document Type", "Document Type");
                SalesReturnOrderLine.SetRange("Document No.", "No.");
                SalesReturnOrderLine.SetFilter("Quantity Invoiced", '<>0');
                if SalesReturnOrderLine.Find('-') then begin
                    SalesReturnOrderLine.SetRange("Quantity Invoiced");
                    SalesReturnOrderLine.SetFilter("Outstanding Quantity", '<>0');
                    OnAfterSetSalesLineFilters(SalesReturnOrderLine);
                    if not SalesReturnOrderLine.Find('-') then begin
                        SalesReturnOrderLine.SetRange("Outstanding Quantity");
                        SalesReturnOrderLine.SetFilter("Return Qty. Rcd. Not Invd.", '<>0');
                        if not SalesReturnOrderLine.Find('-') then begin
                            SalesReturnOrderLine.LockTable();
                            if not SalesReturnOrderLine.Find('-') then begin
                                SalesReturnOrderLine.SetRange("Return Qty. Rcd. Not Invd.");
                                ArchiveManagement.AutoArchiveSalesDocument("Sales Header");
                                if SalesReturnOrderLine.Find('-') then
                                    repeat
                                        if ShouldDeleteSalesOrderLine(SalesReturnOrderLine) then begin
                                            if SalesReturnOrderLine.Type = SalesReturnOrderLine.Type::"Charge (Item)" then begin
                                                ItemChargeAssignmentSales.SetRange("Document Line No.", SalesReturnOrderLine."Line No.");
                                                ItemChargeAssignmentSales.DeleteAll();
                                            end;
                                            IsHandled := false;
                                            OnBeforeDeleteSalesOrderLine(SalesReturnOrderLine, IsHandled);
                                            if not IsHandled then
                                                if SalesReturnOrderLine.HasLinks() then
                                                    SalesReturnOrderLine.DeleteLinks();
                                            SalesReturnOrderLine.Delete();
                                            OnSalesHeaderOnAfterGetRecordOnAfterSalesOrderLineDelete(SalesReturnOrderLine);
                                        end else
                                            AllLinesDeleted := false;
                                    until SalesReturnOrderLine.Next() = 0;

                                if AllLinesDeleted then begin
                                    PostSalesDelete.DeleteHeader(
                                      "Sales Header", SalesShipmentHeader, SalesInvoiceHeader, SalesCrMemoHeader, ReturnReceiptHeader,
                                      PrepaymentSalesInvoiceHeader, PrepaymentSalesCrMemoHeader);
                                    SalesLineReserve.DeleteInvoiceSpecFromHeader("Sales Header");

                                    SalesCommentLine.SetRange("Document Type", "Document Type");
                                    SalesCommentLine.SetRange("No.", "No.");
                                    SalesCommentLine.DeleteAll();

                                    WarehouseRequest.SetRange("Source Type", Database::"Sales Line");
                                    WarehouseRequest.SetRange("Source Subtype", "Document Type");
                                    WarehouseRequest.SetRange("Source No.", "No.");
                                    if not WarehouseRequest.IsEmpty() then
                                        WarehouseRequest.DeleteAll(true);

                                    ApprovalsMgmt.DeleteApprovalEntries(RecordId);

                                    OnBeforeDeleteSalesOrderHeader("Sales Header");
                                    Delete();
                                end;
                                SuppressCommit := false;
                                OnAfterGetRecordSalesHeaderOnBeforeCommit("Sales Header", SuppressCommit);
                                if not SuppressCommit then
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

    var
        ProcessingProgressTxt: Label 'Processing sales return orders #1##########', Comment = '%1 - Sales Return Order No.';

    protected var
        ProgressDialog: Dialog;

    local procedure ShouldDeleteSalesOrderLine(var SalesOrderLine: Record "Sales Line"): Boolean
    begin
        if SalesOrderLine.Type <> SalesOrderLine.Type::"Charge (Item)" then
            exit(true);

        SalesOrderLine.CalcFields("Qty. Assigned");
        if ((SalesOrderLine."Qty. Assigned" = SalesOrderLine."Quantity Invoiced") and (SalesOrderLine."Qty. Assigned" <> 0)) then
            exit(true);

        exit(false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetSalesLineFilters(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteSalesOrderHeader(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteSalesOrderLine(var SalesOrderLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSalesHeaderOnBeforeOnAfterGetRecord(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean; var ProgressDialog: Dialog)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSalesHeaderOnAfterGetRecordOnAfterSalesOrderLineDelete(var SalesOrderLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordSalesHeaderOnBeforeCommit(var SalesHeader: Record "Sales Header"; var SuppressCommit: Boolean)
    begin
    end;
}

