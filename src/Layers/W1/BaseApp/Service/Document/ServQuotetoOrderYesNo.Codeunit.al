// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;
using Microsoft.CRM.Outlook;
using Microsoft.Utilities;
using System.Utilities;

codeunit 5922 "Serv-Quote to Order (Yes/No)"
{
    TableNo = "Service Header";

    trigger OnRun()
    var
        ConfirmManagement: Codeunit "Confirm Management";
        HideMessage: Boolean;
        IsHandled: Boolean;
        SkipTestFields: Boolean;
        SkipConfirm: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnRun(Rec, IsHandled, SkipTestFields, SkipConfirm);
        if IsHandled then
            exit;

        if not SkipTestFields then begin
            Rec.TestField("Document Type", Rec."Document Type"::Quote);
            Rec.TestField("Customer No.");
            Rec.TestField("Bill-to Customer No.");
        end;
        if not SkipConfirm then
            if not ConfirmManagement.GetResponseOrDefault(Text000, true) then
                exit;

        ServQuoteToOrder.Run(Rec);

        OnBeforeShowMessage(Rec, ServQuoteToOrder.ReturnOrderNo(), HideMessage);
        if not HideMessage then
            ShowCreatedOrder(Rec."No.");
    end;

    var
        ServQuoteToOrder: Codeunit "Service-Quote to Order";

#pragma warning disable AA0074
        Text000: Label 'Do you want to convert the quote to an order?';
#pragma warning restore AA0074
        OpenNewOrderQst: Label 'The Service Quote %1 has been converted to Service Order %2. Do you want to open the new Order?', Comment = '%1 - Service Quote number, %2 - Service Order number';

    local procedure ShowCreatedOrder(ServiceQuoteNo: Code[20])
    var
        ServiceHeaderOrder: Record "Service Header";
        ConfirmManagement: Codeunit "Confirm Management";
        OfficeMgt: Codeunit "Office Management";
        PageManagement: Codeunit "Page Management";
        OpenPage: Boolean;
    begin
        if GuiAllowed() then
            if OfficeMgt.AttachAvailable() then
                OpenPage := true
            else
                OpenPage := ConfirmManagement.GetResponseOrDefault(StrSubstNo(OpenNewOrderQst, ServiceQuoteNo, ServQuoteToOrder.ReturnOrderNo()), true);

        if not OpenPage then
            exit;

        ServiceHeaderOrder.Get(ServiceHeaderOrder."Document Type"::Order, ServQuoteToOrder.ReturnOrderNo());
        PageManagement.PageRun(ServiceHeaderOrder);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowMessage(var Rec: Record "Service Header"; OrderNo: Code[20]; var HideMessage: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var ServiceHeader: Record "Service Header"; var IsHandled: Boolean; var SkipTestFields: Boolean; var SkipConfirm: Boolean)
    begin
    end;
}

