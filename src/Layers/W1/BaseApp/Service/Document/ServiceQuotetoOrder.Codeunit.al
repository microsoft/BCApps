// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Foundation.NoSeries;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Service.Comment;
using Microsoft.Service.Loaner;
using Microsoft.Service.Maintenance;
using Microsoft.Service.Setup;
using System.Automation;
using System.Utilities;
using Microsoft.Inventory.Availability;

codeunit 5923 "Service-Quote to Order"
{
    Permissions = TableData "Loaner Entry" = rm,
                  TableData "Service Order Allocation" = rimd;
    TableNo = "Service Header";

    trigger OnRun()
    var
        ServQuoteLine: Record "Service Line";
        Customer: Record Customer;
        ServCheckCreditLimit: Codeunit "Serv. Check Credit Limit";
        DocType: Enum "Sales Document Type";
        SkipDelete: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRun(Rec, IsHandled);
        if IsHandled then
            exit;

        ServOrderHeader := Rec;

        ServMgtSetup.Get();

        ServOrderHeader."Document Type" := Rec."Document Type"::Order;
        OnRunOnAfterGetServMgtSetup(ServOrderHeader, Rec);
        Customer.Get(Rec."Customer No.");
        IsHandled := false;
        OnRunOnBeforeCheckBlockedCustOnDocs(ServOrderHeader, Rec, IsHandled);
        if not IsHandled then begin
            Customer.CheckBlockedCustOnDocs(Customer, DocType::Quote, false, false);
            if Rec."Customer No." <> Rec."Bill-to Customer No." then begin
                Customer.Get(Rec."Bill-to Customer No.");
                Customer.CheckBlockedCustOnDocs(Customer, DocType::Quote, false, false);
            end;
        end;

        Rec.ValidateSalesPersonOnServiceHeader(Rec, true, false);

        ServCheckCreditLimit.ServiceHeaderCheck(ServOrderHeader);

        CheckServiceItemBlockedForAll(Rec);
        CheckItemServiceBlocked(Rec);

        TransferQuoteToOrderLines(ServQuoteLine, Rec, ServOrderLine, ServOrderHeader);

        MakeOrder(Rec);

        SkipDelete := false;
        OnBeforeServHeaderDelete(Rec, SkipDelete);
        if not SkipDelete then
            Rec.Delete(true);
    end;

    var
        ServMgtSetup: Record "Service Mgt. Setup";
        RepairStatus: Record "Repair Status";
        ServItemLine: Record "Service Item Line";
        ServItemLine2: Record "Service Item Line";
        ServOrderLine: Record "Service Line";
        ServOrderLine2: Record "Service Line";
        ServOrderAlloc: Record "Service Order Allocation";
        ServOrderHeader: Record "Service Header";
        LoanerEntry: Record "Loaner Entry";
        ServCommentLine: Record "Service Comment Line";
        ServCommentLine2: Record "Service Comment Line";
        ServLogMgt: Codeunit ServLogManagement;
        ServiceLineReserve: Codeunit "Service Line-Reserve";

    local procedure TestNoSeries()
    begin
        ServMgtSetup.TestField("Service Order Nos.");
    end;

    local procedure GetNoSeriesCode() NoSeriesCode: Code[20]
    begin
        NoSeriesCode := ServMgtSetup."Service Order Nos.";

        OnAfterGetNoSeriesCode(ServOrderHeader, ServMgtSetup, NoSeriesCode);
    end;

    procedure ReturnOrderNo(): Code[20]
    begin
        exit(ServOrderHeader."No.");
    end;

    local procedure InsertServHeader(var ServiceHeaderOrder: Record "Service Header"; ServiceHeaderQuote: Record "Service Header")
    begin
        OnBeforeInsertServHeader(ServiceHeaderOrder, ServiceHeaderQuote);

        ServiceHeaderOrder.Insert(true);
        ServiceHeaderOrder."Document Date" := ServiceHeaderQuote."Document Date";
        ServiceHeaderOrder."Shortcut Dimension 1 Code" := ServiceHeaderQuote."Shortcut Dimension 1 Code";
        ServiceHeaderOrder."Shortcut Dimension 2 Code" := ServiceHeaderQuote."Shortcut Dimension 2 Code";
        ServiceHeaderOrder."Dimension Set ID" := ServiceHeaderQuote."Dimension Set ID";
        ServiceHeaderOrder."Location Code" := ServiceHeaderQuote."Location Code";
        ServiceHeaderQuote.CalcFields("Work Description");
        ServiceHeaderOrder."Work Description" := ServiceHeaderQuote."Work Description";
        OnBeforeServiceHeaderOrderModify(ServiceHeaderOrder, ServiceHeaderQuote);
        ServiceHeaderOrder.Modify();

        OnAfterInsertServHeader(ServiceHeaderOrder, ServiceHeaderQuote);
    end;

    local procedure MakeOrder(ServiceHeader: Record "Service Header")
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        RecordLinkManagement: Codeunit "Record Link Management";
        NoSeries: Codeunit "No. Series";
        SkipDelete: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeMakeOrder(ServiceHeader, ServOrderHeader, IsHandled);
        if IsHandled then
            exit;

        ServOrderHeader."No." := '';
        ServOrderHeader."No. Printed" := 0;
        ServOrderHeader.Validate(Status, ServOrderHeader.Status::Pending);
        ServOrderHeader."Order Date" := WorkDate();
        ServOrderHeader."Order Time" := Time;
        ServOrderHeader."Actual Response Time (Hours)" := 0;
        ServOrderHeader."Service Time (Hours)" := 0;
        ServOrderHeader."Starting Date" := 0D;
        ServOrderHeader."Starting Time" := 0T;
        ServOrderHeader."Finishing Date" := 0D;
        ServOrderHeader."Finishing Time" := 0T;
        ServOrderHeader."Posting Date" := 0D;

        IsHandled := false;
        OnMakeOrderOnBeforeTestNoSeries(ServOrderHeader, IsHandled);
        if not IsHandled then begin
            TestNoSeries();
            ServOrderHeader."No. Series" := GetNoSeriesCode();
            ServOrderHeader."No." := NoSeries.GetNextNo(ServOrderHeader."No. Series");

            ServOrderHeader."Quote No." := ServiceHeader."No.";
        end;
        RecordLinkManagement.CopyLinks(ServiceHeader, ServOrderHeader);
        InsertServHeader(ServOrderHeader, ServiceHeader);

        ServCommentLine.Reset();
        ServCommentLine.SetRange("Table Name", ServCommentLine."Table Name"::"Service Header");
        ServCommentLine.SetRange("Table Subtype", ServiceHeader."Document Type");
        ServCommentLine.SetRange("No.", ServiceHeader."No.");
        ServCommentLine.SetRange("Table Line No.", 0);
        if ServCommentLine.Find('-') then
            repeat
                ServCommentLine2 := ServCommentLine;
                ServCommentLine2."Table Subtype" := ServOrderHeader."Document Type";
                ServCommentLine2."No." := ServOrderHeader."No.";
                OnBeforeServCommentLineInsert(ServCommentLine2, ServiceHeader, ServOrderHeader);
                ServCommentLine2.Insert();
            until ServCommentLine.Next() = 0;

        ServOrderAlloc.Reset();
        ServOrderAlloc.SetCurrentKey("Document Type", "Document No.", Status);
        ServOrderAlloc.SetRange("Document Type", ServiceHeader."Document Type");
        ServOrderAlloc.SetRange("Document No.", ServiceHeader."No.");
        ServOrderAlloc.SetRange(Status, ServOrderAlloc.Status::Active);
        while ServOrderAlloc.FindFirst() do begin
            ServOrderAlloc."Document Type" := ServOrderHeader."Document Type";
            ServOrderAlloc."Document No." := ServOrderHeader."No.";
            ServOrderAlloc."Service Started" := true;
            ServOrderAlloc.Status := ServOrderAlloc.Status::"Reallocation Needed";
            ServOrderAlloc.Modify();
        end;

        ServItemLine.Reset();
        ServItemLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServItemLine.SetRange("Document No.", ServiceHeader."No.");
        if ServItemLine.Find('-') then
            repeat
                ServItemLine2 := ServItemLine;
                ServItemLine2."Document Type" := ServOrderHeader."Document Type";
                ServItemLine2."Document No." := ServOrderHeader."No.";
                ServItemLine2."Starting Date" := 0D;
                ServItemLine2."Starting Time" := 0T;
                ServItemLine2."Actual Response Time (Hours)" := 0;
                ServItemLine2."Finishing Date" := 0D;
                ServItemLine2."Finishing Time" := 0T;
                RepairStatus.Reset();
                RepairStatus.SetRange(Initial, true);
                if RepairStatus.FindFirst() then
                    ServItemLine2."Repair Status Code" := RepairStatus.Code;
                OnBeforeServiceItemLineInsert(ServItemLine2, ServItemLine, ServOrderHeader);
                ServItemLine2.Insert(true);
                OnAfterInsertServiceLine(ServItemLine2, ServItemLine);
            until ServItemLine.Next() = 0;

        ServOrderHeader.UpdateResponseDateTime();

        LoanerEntry.Reset();
        LoanerEntry.SetCurrentKey("Document Type", "Document No.");
        LoanerEntry.SetRange("Document Type", ServiceHeader."Document Type".AsInteger() + 1);
        LoanerEntry.SetRange("Document No.", ServiceHeader."No.");
        while LoanerEntry.FindFirst() do begin
            LoanerEntry."Document Type" := LoanerEntry.GetDocTypeFromServDocType(ServOrderHeader."Document Type");
            LoanerEntry."Document No." := ServOrderHeader."No.";
            LoanerEntry.Modify();
        end;

        ServCommentLine.Reset();
        ServCommentLine.SetRange("Table Name", ServCommentLine."Table Name"::"Service Header");
        ServCommentLine.SetRange("Table Subtype", ServiceHeader."Document Type");
        ServCommentLine.SetRange("No.", ServiceHeader."No.");
        ServCommentLine.SetFilter("Table Line No.", '>%1', 0);
        if ServCommentLine.Find('-') then
            repeat
                ServCommentLine2 := ServCommentLine;
                ServCommentLine2."Table Subtype" := ServOrderHeader."Document Type";
                ServCommentLine2."No." := ServOrderHeader."No.";
                OnMakeOrderOnBeforeServCommentLine2Insert(ServCommentLine2, ServCommentLine);
                ServCommentLine2.Insert();
            until ServCommentLine.Next() = 0;

        ServOrderLine.Reset();
        ServOrderLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServOrderLine.SetRange("Document No.", ServiceHeader."No.");
        if ServOrderLine.Find('-') then
            repeat
                ServOrderLine2 := ServOrderLine;
                ServOrderLine2."Document Type" := ServOrderHeader."Document Type";
                ServOrderLine2."Document No." := ServOrderHeader."No.";
                ServOrderLine2."Posting Date" := ServOrderHeader."Posting Date";
                IsHandled := false;
                OnBeforeServOrderLineInsert(ServOrderLine2, ServOrderLine, ServOrderHeader, IsHandled);
                if not IsHandled then
                    ServOrderLine2.Insert();
                OnAfterServOrderLineInsert(ServOrderLine2, ServOrderLine);
                ServiceLineReserve.TransServLineToServLine(ServOrderLine, ServOrderLine2, ServOrderLine.Quantity);
            until ServOrderLine.Next() = 0;

        ServLogMgt.ServOrderQuoteChanged(ServOrderHeader, ServiceHeader);
        ApprovalsMgmt.CopyApprovalEntryQuoteToOrder(
            ServiceHeader.RecordId, ServOrderHeader."No.", ServOrderHeader.RecordId);

        SkipDelete := false;
        OnBeforeServLineDeleteAll(ServiceHeader, ServOrderHeader, SkipDelete);
        if not SkipDelete then
            ApprovalsMgmt.DeleteApprovalEntries(ServiceHeader.RecordId);
    end;

    local procedure TransferQuoteToOrderLines(var ServiceQuoteLine: Record "Service Line"; var ServiceQuoteHeader: Record "Service Header"; var ServiceOrderLine: Record "Service Line"; var ServiceOrderHeader: Record "Service Header")
    var
        ServItemCheckAvail: Codeunit "Serv. Item Check Avail.";
        IsHandled: Boolean;
    begin
        ServiceQuoteLine.Reset();
        ServiceQuoteLine.SetRange("Document Type", ServiceQuoteHeader."Document Type");
        ServiceQuoteLine.SetRange("Document No.", ServiceQuoteHeader."No.");
        ServiceQuoteLine.SetRange(Type, ServiceQuoteLine.Type::Item);
        ServiceQuoteLine.SetFilter("No.", '<>%1', '');
        OnTransferQuoteToOrderLinesOnAfterServiceQuoteLineSetFilters(ServiceQuoteLine);
        if ServiceQuoteLine.FindSet() then
            repeat
                IsHandled := false;
                OnBeforeTransferQuoteLineToOrderLineLoop(ServiceQuoteLine, ServiceQuoteHeader, ServiceOrderHeader, IsHandled, ServiceOrderLine, ServOrderLine);
                if not IsHandled then begin
                    ServiceOrderLine := ServiceQuoteLine;
                    ServiceLineReserve.TransServLineToServLine(
                      ServiceQuoteLine, ServiceOrderLine, ServiceQuoteLine."Outstanding Qty. (Base)");
                    ServiceOrderLine."Line No." := 0;
                    ServiceOrderLine.Validate("Reserved Qty. (Base)");
                    if GuiAllowed then
                        if ServItemCheckAvail.ServiceInvLineCheck(ServiceOrderLine) then
                            ServItemCheckAvail.RaiseUpdateInterruptedError();
                end;
            until ServiceQuoteLine.Next() = 0;
    end;

    local procedure CheckServiceItemBlockedForAll(ServiceQuoteHeader: Record "Service Header")
    var
        ServiceItemLine: Record "Service Item Line";
        ServOrderManagement: Codeunit ServOrderManagement;
    begin
        ServiceItemLine.SetLoadFields("Service Item No.");
        ServiceItemLine.SetRange("Document Type", ServiceQuoteHeader."Document Type");
        ServiceItemLine.SetRange("Document No.", ServiceQuoteHeader."No.");
        ServiceItemLine.SetFilter("Service Item No.", '<>%1', '');
        if ServiceItemLine.FindSet() then
            repeat
                ServOrderManagement.CheckServiceItemBlockedForAll(ServiceItemLine);
            until ServiceItemLine.Next() = 0;
    end;

    local procedure CheckItemServiceBlocked(ServiceQuoteHeader: Record "Service Header")
    var
        ServiceQuoteLine: Record "Service Line";
        ServOrderManagement: Codeunit ServOrderManagement;
    begin
        ServiceQuoteLine.SetLoadFields("No.", "Variant Code");
        ServiceQuoteLine.SetRange("Document Type", ServiceQuoteHeader."Document Type");
        ServiceQuoteLine.SetRange("Document No.", ServiceQuoteHeader."No.");
        ServiceQuoteLine.SetRange(Type, ServiceQuoteLine.Type::Item);
        ServiceQuoteLine.SetFilter("No.", '<>%1', '');
        if ServiceQuoteLine.FindSet() then
            repeat
                ServOrderManagement.CheckItemServiceBlocked(ServiceQuoteLine);
            until ServiceQuoteLine.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRun(var ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetNoSeriesCode(var ServOrderHeader: Record "Service Header"; ServMgtSetup: Record "Service Mgt. Setup"; var NoSeriesCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertServHeader(var ServiceHeaderOrder: Record "Service Header"; ServiceHeaderQuote: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertServiceLine(var ServiceItemLine2: Record "Service Item Line"; ServiceItemLine: Record "Service Item Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterServOrderLineInsert(var ServiceOrderLine2: Record "Service Line"; ServiceOrderLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertServHeader(var ServiceHeaderOrder: Record "Service Header"; ServiceHeaderQuote: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMakeOrder(var ServiceHeader: Record "Service Header"; var ServOrderHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServCommentLineInsert(var ServiceCommentLine: Record "Service Comment Line"; ServiceQuoteHeader: Record "Service Header"; ServiceOrderHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServHeaderDelete(var ServiceHeader: Record "Service Header"; var SkipDelete: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServLineDeleteAll(var ServiceHeader: Record "Service Header"; var NewServiceHeader: Record "Service Header"; var SkipDelete: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServOrderLineInsert(var ServiceOrderLine2: Record "Service Line"; ServiceOrderLine: Record "Service Line"; ServOrderHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceHeaderOrderModify(var ServiceOrderHeader: Record "Service Header"; ServiceQuoteHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceItemLineInsert(var ServiceItemLine2: Record "Service Item Line"; ServiceItemLine: Record "Service Item Line"; ServOrderHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferQuoteLineToOrderLineLoop(var ServiceQuoteLine: Record "Service Line"; var ServiceQuoteHeader: Record "Service Header"; var ServiceOrderHeader: Record "Service Header"; var IsHandled: Boolean; var ServiceOrderLine: Record "Service Line"; var ServiceOrderLineGlobal: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMakeOrderOnBeforeServCommentLine2Insert(var ServiceCommentLine2: Record "Service Comment Line"; var ServiceCommentLine: Record "Service Comment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterGetServMgtSetup(var ServOrderHeader: Record "Service Header"; Rec: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeCheckBlockedCustOnDocs(var ServiceHeaderOrder: Record "Service Header"; var ServiceHeader: Record "Service Header"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferQuoteToOrderLinesOnAfterServiceQuoteLineSetFilters(var QuoteServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnMakeOrderOnBeforeTestNoSeries(var ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;
}