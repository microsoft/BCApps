// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Assembly.Document;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Comment;
using Microsoft.Sales.History;
using Microsoft.Utilities;
using Microsoft.Warehouse.Request;
using System.Automation;

report 299 "Delete Invoiced Sales Orders"
{
    AccessByPermission = TableData "Sales Header" = RD;
    ApplicationArea = Basic, Suite;
    Caption = 'Delete Invoiced Sales Orders';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("Sales Header"; "Sales Header")
        {
            DataItemTableView = sorting("Document Type", "No.") where("Document Type" = const(Order));
            RequestFilterFields = "No.", "Sell-to Customer No.", "Bill-to Customer No.";
            RequestFilterHeading = 'Sales Order';

            trigger OnAfterGetRecord()
            var
                SalesOrderLine: Record "Sales Line";
                SalesShipmentHeader: Record "Sales Shipment Header";
                SalesInvoiceHeader: Record "Sales Invoice Header";
                SalesCrMemoHeader: Record "Sales Cr.Memo Header";
                ReturnReceiptHeader: Record "Return Receipt Header";
                PrepaymentSalesInvoiceHeader: Record "Sales Invoice Header";
                PrepaymentSalesCrMemoHeader: Record "Sales Cr.Memo Header";
                SalesCommentLine: Record "Sales Comment Line";
                WarehouseRequest: Record "Warehouse Request";
                AssembleToOrderLink: Record "Assemble-to-Order Link";
                ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
                SalesLineReserve: Codeunit "Sales Line-Reserve";
                ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                ArchiveManagement: Codeunit ArchiveManagement;
                PostSalesDelete: Codeunit "PostSales-Delete";
                AllLinesDeleted: Boolean;
                IsHandled: Boolean;
                SkipLine: Boolean;
                SuppressCommit: Boolean;
            begin
                IsHandled := false;
                OnBeforeSalesHeaderOnAfterGetRecord("Sales Header", IsHandled, ProgressDialog);
                if IsHandled then
                    CurrReport.Skip();

                if GuiAllowed() then
                    ProgressDialog.Update(1, "No.");

                AllLinesDeleted := true;
                ItemChargeAssignmentSales.SetRange("Document Type", "Document Type");
                ItemChargeAssignmentSales.SetRange("Document No.", "No.");
                SalesOrderLine.SetRange("Document Type", "Document Type");
                SalesOrderLine.SetRange("Document No.", "No.");
                SalesOrderLine.SetFilter("Quantity Invoiced", '<>0');
                SkipLine := false;
                OnAfterGetRecordSalesHeaderOnBeforeFirstSalesOrderLineFind(SalesOrderLine, SkipLine);
                if not SkipLine then
                    if SalesOrderLine.Find('-') then begin
                        SalesOrderLine.SetRange("Quantity Invoiced");
                        SalesOrderLine.SetFilter("Outstanding Quantity", '<>0');
                        OnAfterSetSalesLineFilters(SalesOrderLine);
                        if not SalesOrderLine.Find('-') then begin
                            SalesOrderLine.SetRange("Outstanding Quantity");
                            SalesOrderLine.SetFilter("Qty. Shipped Not Invoiced", '<>0');
                            if not SalesOrderLine.Find('-') then begin
                                SalesOrderLine.LockTable();
                                if not SalesOrderLine.Find('-') then begin
                                    SalesOrderLine.SetRange("Qty. Shipped Not Invoiced");

                                    IsHandled := false;
                                    OnSalesHeaderOnAfterGetRecordOnBeforeAutoArchiveSalesDocument(IsHandled, "Sales Header");
                                    if not IsHandled then
                                        ArchiveManagement.AutoArchiveSalesDocument("Sales Header");

                                    OnBeforeDeleteSalesLinesLoop("Sales Header", SalesOrderLine);
                                    if SalesOrderLine.Find('-') then
                                        repeat
                                            if ShouldDeleteSalesOrderLine(SalesOrderLine) then begin
                                                if SalesOrderLine.Type = SalesOrderLine.Type::"Charge (Item)" then begin
                                                    ItemChargeAssignmentSales.SetRange("Document Line No.", SalesOrderLine."Line No.");
                                                    ItemChargeAssignmentSales.DeleteAll();
                                                end;
                                                if SalesOrderLine.Type = SalesOrderLine.Type::Item then
                                                    AssembleToOrderLink.DeleteAsmFromSalesLine(SalesOrderLine);

                                                IsHandled := false;
                                                OnSalesHeaderOnAfterGetRecordOnBeforeSalesOrderLineDeleteLinks(IsHandled, SalesOrderLine);
                                                if not IsHandled then
                                                    if SalesOrderLine.HasLinks() then
                                                        SalesOrderLine.DeleteLinks();
                                                SalesOrderLine.Delete();
                                                OnAfterDeleteSalesLine(SalesOrderLine);
                                            end else
                                                AllLinesDeleted := false;
                                            UpdateAssociatedPurchOrder(SalesOrderLine);
                                        until SalesOrderLine.Next() = 0;
                                    OnAfterDeleteSalesLinesLoop("Sales Header", AllLinesDeleted);

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

                                        IsHandled := false;
                                        OnSalesHeaderOnAfterGetRecordOnBeforeDeleteLinks(IsHandled, Invoice);
                                        if not IsHandled then
                                            if HasLinks() then
                                                DeleteLinks();

                                        OnBeforeDeleteSalesHeader("Sales Header");
                                        Delete();
                                        OnAfterDeleteSalesHeader("Sales Header");
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
        ProcessingProgressTxt: Label 'Processing sales orders #1##########', Comment = '%1 - Sales Order No.';

    protected var
        ProgressDialog: Dialog;

    local procedure UpdateAssociatedPurchOrder(var SalesOrderLine: Record "Sales Line")
    var
        PurchaseLine: Record "Purchase Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateAssociatedPurchOrder(SalesOrderLine, PurchaseLine, IsHandled);
        if IsHandled then
            exit;

        if SalesOrderLine."Special Order" then
            if PurchaseLine.Get(
                 PurchaseLine."Document Type"::Order, SalesOrderLine."Special Order Purchase No.", SalesOrderLine."Special Order Purch. Line No.")
            then begin
                PurchaseLine."Special Order Sales No." := '';
                PurchaseLine."Special Order Sales Line No." := 0;
                PurchaseLine.Modify();
            end;

        if SalesOrderLine."Drop Shipment" then
            if PurchaseLine.Get(
                 PurchaseLine."Document Type"::Order, SalesOrderLine."Purchase Order No.", SalesOrderLine."Purch. Order Line No.")
            then begin
                PurchaseLine."Sales Order No." := '';
                PurchaseLine."Sales Order Line No." := 0;
                PurchaseLine.Modify();
            end;
    end;

    local procedure ShouldDeleteSalesOrderLine(var SalesOrderLine: Record "Sales Line"): Boolean
    begin
        if SalesOrderLine.Type <> SalesOrderLine.Type::"Charge (Item)" then
            exit(true);

        SalesOrderLine.CalcFields("Qty. Assigned");
        if SalesOrderLine."Qty. Assigned" = SalesOrderLine."Quantity Invoiced" then
            exit(true);

        if IsPostedUnassignedItemChargeWithZeroAmount(SalesOrderLine) then
            exit(true);

        exit(false);
    end;

    local procedure IsPostedUnassignedItemChargeWithZeroAmount(SalesLine: Record "Sales Line"): Boolean
    begin
        if (SalesLine.Type = SalesLine.Type::"Charge (Item)") and
           (SalesLine.Quantity = SalesLine."Quantity Invoiced") and
           (SalesLine.Amount = 0)
        then begin
            SalesLine.CalcFields("Qty. Assigned");
            if SalesLine."Qty. Assigned" = 0 then
                exit(true);
        end;

        exit(false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteSalesLine(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteSalesLinesLoop(var SalesHeader: Record "Sales Header"; AllLinesDeleted: Boolean)
    begin
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
    local procedure OnBeforeDeleteSalesLinesLoop(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesHeaderOnAfterGetRecord(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean; var ProgressDialog: Dialog)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateAssociatedPurchOrder(var SalesOrderLine: Record "Sales Line"; var PurchLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSalesHeaderOnAfterGetRecordOnBeforeAutoArchiveSalesDocument(var IsHandled: Boolean; var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSalesHeaderOnAfterGetRecordOnBeforeSalesOrderLineDeleteLinks(var IsHandled: Boolean; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSalesHeaderOnAfterGetRecordOnBeforeDeleteLinks(var IsHandled: Boolean; var Invoice: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteSalesHeader(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordSalesHeaderOnBeforeFirstSalesOrderLineFind(var SalesLine: Record "Sales Line"; var SkipLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordSalesHeaderOnBeforeCommit(var SalesHeader: Record "Sales Header"; var SuppressCommit: Boolean)
    begin
    end;
}

