// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Posting;

using Microsoft.Service.Document;
using Microsoft.Service.History;

codeunit 5982 "Service-Post+Print"
{
    TableNo = "Service Header";

    trigger OnRun()
    begin
        PostDocument(Rec);
    end;

    var
        ServiceHeader: Record "Service Header";
        ServShptHeader: Record "Service Shipment Header";
        ServInvHeader: Record "Service Invoice Header";
        ServCrMemoHeader: Record "Service Cr.Memo Header";
        ServicePost: Codeunit "Service-Post";
        Ship: Boolean;
        Consume: Boolean;
        Invoice: Boolean;

    procedure PostDocument(var Rec: Record "Service Header")
    var
        TempServiceLine: Record "Service Line" temporary;
    begin
        OnBeforePostDocument(Rec);
        ServiceHeader.Copy(Rec);
        Code(TempServiceLine);
        Rec := ServiceHeader;
    end;

    local procedure "Code"(var PassedServLine: Record "Service Line")
    var
        HideDialog: Boolean;
        IsHandled: Boolean;
        DefaultOption: Integer;
    begin
        HideDialog := false;
        IsHandled := false;
        DefaultOption := 3;
        OnBeforeConfirmPost(ServiceHeader, HideDialog, Ship, Consume, Invoice, IsHandled, PassedServLine);
        if IsHandled then
            exit;

        if not HideDialog then
            if not ConfirmPostAndPrint(ServiceHeader, DefaultOption) then
                exit;

        OnAfterConfirmPost(ServiceHeader, Ship, Consume, Invoice);

        ServicePost.PostWithLines(ServiceHeader, PassedServLine, Ship, Consume, Invoice);
        OnAfterPost(ServiceHeader);

        GetReport(ServiceHeader);
        Commit();

    end;

    procedure GetReport(var ServiceHeader: Record "Service Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetReport(ServiceHeader, IsHandled);
        if IsHandled then
            exit;

        case ServiceHeader."Document Type" of
            ServiceHeader."Document Type"::Order:
                begin
                    if Ship then begin
                        ServShptHeader."No." := ServiceHeader."Last Shipping No.";
                        ServShptHeader.SetRecFilter();
                        IsHandled := false;
                        OnBeforeServiceShipmentHeaderPrintRecords(ServShptHeader, IsHandled);
                        if not IsHandled then
                            ServShptHeader.PrintRecords(false);
                    end;
                    if Invoice then begin
                        ServInvHeader."No." := ServiceHeader."Last Posting No.";
                        ServInvHeader.SetRecFilter();
                        IsHandled := false;
                        OnBeforeServiceInvoiceHeaderPrintRecords(ServInvHeader, IsHandled);
                        if not IsHandled then
                            ServInvHeader.PrintRecords(false);
                    end;
                end;
            ServiceHeader."Document Type"::Invoice:
                begin
                    if ServiceHeader."Last Posting No." = '' then
                        ServInvHeader."No." := ServiceHeader."No."
                    else
                        ServInvHeader."No." := ServiceHeader."Last Posting No.";
                    ServInvHeader.SetRecFilter();
                    IsHandled := false;
                    OnBeforeServiceInvoiceHeaderPrintRecords(ServInvHeader, IsHandled);
                    if not IsHandled then
                        ServInvHeader.PrintRecords(false);
                end;
            ServiceHeader."Document Type"::"Credit Memo":
                begin
                    if ServiceHeader."Last Posting No." = '' then
                        ServCrMemoHeader."No." := ServiceHeader."No."
                    else
                        ServCrMemoHeader."No." := ServiceHeader."Last Posting No.";
                    ServCrMemoHeader.SetRecFilter();
                    IsHandled := false;
                    OnBeforeServiceCrMemoHeaderPrintRecords(ServCrMemoHeader, IsHandled);
                    if not IsHandled then
                        ServCrMemoHeader.PrintRecords(false);
                end;
        end;
    end;

    local procedure ConfirmPostAndPrint(var PassedServiceHeader: Record "Service Header"; DefaultOption: Integer) Result: Boolean
    var
        ServPostingSelectionMgt: Codeunit "Serv. Posting Selection Mgt.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeConfirmPostAndPrint(PassedServiceHeader, Ship, Consume, Invoice, DefaultOption, Result, IsHandled);
        if IsHandled then
            exit(Result);

        Result := ServPostingSelectionMgt.ConfirmPostServiceDocument(PassedServiceHeader, Ship, Consume, Invoice, DefaultOption, true, false, false);
        if not Result then
            exit(false);

        exit(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterConfirmPost(var ServiceHeader: Record "Service Header"; Ship: Boolean; Consume: Boolean; Invoice: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPost(var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmPost(var ServiceHeader: Record "Service Header"; var HideDialog: Boolean; var Ship: Boolean; var Consume: Boolean; var Invoice: Boolean; var IsHandled: Boolean; var PassedServLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetReport(var ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceCrMemoHeaderPrintRecords(var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceInvoiceHeaderPrintRecords(var ServiceInvoiceHeader: Record "Service Invoice Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceShipmentHeaderPrintRecords(var ServiceShipmentHeader: Record "Service Shipment Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostDocument(var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmPostAndPrint(var ServiceHeader: Record "Service Header"; var Ship: Boolean; var Consume: Boolean; var Invoice: Boolean; var DefaultOption: Integer; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
}

