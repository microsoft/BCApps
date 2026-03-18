// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Service.Comment;
using Microsoft.Service.History;
using Microsoft.Service.Posting;
using Microsoft.Warehouse.Request;
using System.Automation;
using System.Telemetry;

report 5914 "Delete Invoiced Service Orders"
{
    AccessByPermission = TableData "Service Header" = RD;
    ApplicationArea = Service;
    Caption = 'Delete Invoiced Service Orders';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("Service Header"; "Service Header")
        {
            DataItemTableView = sorting("Document Type", "No.") where("Document Type" = const(Order));
            RequestFilterFields = "No.", "Customer No.", "Bill-to Customer No.";
            RequestFilterHeading = 'Service Order';

            trigger OnAfterGetRecord()
            var
                ServiceOrderItemLine: Record "Service Item Line";
                ServiceOrderLine: Record "Service Line";
                ServiceShipmentHeader: Record "Service Shipment Header";
                ServiceInvoiceHeader: Record "Service Invoice Header";
                ServiceCrMemoHeader: Record "Service Cr.Memo Header";
                ServiceCommentLine: Record "Service Comment Line";
                WarehouseRequest: Record "Warehouse Request";
                ServiceOrderAllocation: Record "Service Order Allocation";
                ServicePost: Codeunit "Service-Post";
                ServiceLineReserve: Codeunit "Service Line-Reserve";
                ServAllocationManagement: Codeunit ServAllocationManagement;
                ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeServiceHeaderOnAfterGetRecord("Service Header", IsHandled, ProgressDialog);
                if IsHandled then
                    CurrReport.Skip();

                if GuiAllowed() then
                    ProgressDialog.Update(1, "No.");

                ServiceOrderLine.SetRange("Document Type", "Document Type");
                ServiceOrderLine.SetRange("Document No.", "No.");
                ServiceOrderLine.SetFilter("Quantity Invoiced", '<>0');
                if ServiceOrderLine.Find('-') then begin
                    ServiceOrderLine.SetRange("Quantity Invoiced");
                    ServiceOrderLine.SetFilter("Outstanding Quantity", '<>0');
                    if not ServiceOrderLine.Find('-') then begin
                        ServiceOrderLine.SetRange("Outstanding Quantity");
                        ServiceOrderLine.SetFilter("Qty. Shipped Not Invoiced", '<>0');
                        if not ServiceOrderLine.Find('-') then begin
                            ServiceOrderLine.LockTable();
                            if not ServiceOrderLine.Find('-') then begin
                                ServiceOrderLine.SetRange("Qty. Shipped Not Invoiced");
                                if ServiceOrderLine.Find('-') then
                                    repeat
                                        OnBeforeDeleteServiceOrderLine(ServiceOrderLine);
                                        ServiceOrderLine.Delete();
                                    until ServiceOrderLine.Next() = 0;

                                ServiceOrderItemLine.Reset();
                                ServiceOrderItemLine.SetRange("Document Type", "Document Type");
                                ServiceOrderItemLine.SetRange("Document No.", "No.");
                                if ServiceOrderItemLine.FindSet() then
                                    repeat
                                        OnBeforeDeleteServiceOrderItemLine(ServiceOrderItemLine);
                                        ServiceOrderItemLine.Delete();
                                    until ServiceOrderItemLine.Next() = 0;

                                ServicePost.DeleteHeader("Service Header", ServiceShipmentHeader, ServiceInvoiceHeader, ServiceCrMemoHeader);

                                ServiceLineReserve.DeleteInvoiceSpecFromHeader("Service Header");

                                ServiceCommentLine.SetRange("No.", "No.");
                                ServiceCommentLine.SetRange("Table Name", ServiceCommentLine."Table Name"::"Service Header");
                                ServiceCommentLine.SetRange("Table Subtype", "Document Type");
                                ServiceCommentLine.DeleteAll();

                                WarehouseRequest.SetRange("Source Type", Database::"Service Line");
                                WarehouseRequest.SetRange("Source Subtype", "Document Type");
                                WarehouseRequest.SetRange("Source No.", "No.");
                                if not WarehouseRequest.IsEmpty() then
                                    WarehouseRequest.DeleteAll(true);

                                ServiceOrderAllocation.Reset();
                                ServiceOrderAllocation.SetCurrentKey("Document Type");
                                ServiceOrderAllocation.SetRange("Document Type", "Document Type");
                                ServiceOrderAllocation.SetRange("Document No.", "No.");
                                ServiceOrderAllocation.SetRange(Posted, false);
                                ServiceOrderAllocation.DeleteAll();
                                ServAllocationManagement.SetServOrderAllocStatus("Service Header");

                                ApprovalsMgmt.DeleteApprovalEntries(RecordId);

                                OnBeforeDeleteServiceHeader("Service Header");

                                Delete();
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
        }
    }

    trigger OnPostReport()
    var
        AuditLog: Codeunit "Audit Log";
    begin
        AuditLog.LogAuditMessage(StrSubstNo(DeletedInvoicedServiceOrdersLbl, UserSecurityId(), CompanyName()), SecurityOperationResult::Success, AuditCategory::ApplicationManagement, 3, 0);
    end;

    var
        ProgressDialog: Dialog;
        ProcessingProgressTxt: Label 'Processing Service orders #1##########', Comment = '%1 - Service Order No.';
        DeletedInvoicedServiceOrdersLbl: Label 'Invoiced service orders deleted by UserSecurityId %1 for company %2.', Comment = '%1 - User Security ID, %2 - Company name', Locked = true;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteServiceHeader(var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteServiceOrderLine(ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteServiceOrderItemLine(ServiceItemLine: Record "Service Item Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceHeaderOnAfterGetRecord(var ServiceHeader: Record "Service Header"; var IsHandled: Boolean; var ProgressDialog: Dialog)
    begin
    end;
}

