// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using System.Environment.Configuration;

codeunit 1320 "Lines Instruction Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        LinesMissingQuantityConfirmQst: Label 'One or more document lines with a value in the No. field do not have a quantity specified. \Do you want to continue?';

    procedure SalesCheckAllLinesHaveQuantityAssigned(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        MyNotifications: Record "My Notifications";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSalesCheckAllLinesHaveQuantityAssigned(SalesHeader, IsHandled);
        if IsHandled then
            exit;

        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetFilter(Type, '<>%1', SalesLine.Type::" ");
        SalesLine.SetFilter("No.", '<>%1', '');
        SalesLine.SetRange(Quantity, 0);
        OnAfterSetSalesLineFilters(SalesLine, SalesHeader);

        if not SalesLine.IsEmpty() and GuiAllowed() then
            if MyNotifications.IsEnabled(SalesHeader.GetWarnWhenZeroQuantitySalesLinePosting()) then
                if Confirm(LinesMissingQuantityConfirmQst, false) then
                    exit
                else
                    Error('');
    end;

    procedure PurchaseCheckAllLinesHaveQuantityAssigned(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        MyNotifications: Record "My Notifications";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePurchaseCheckAllLinesHaveQuantityAssigned(PurchaseHeader, IsHandled);
        if IsHandled then
            exit;

        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetFilter(Type, '<>%1', PurchaseLine.Type::" ");
        PurchaseLine.SetFilter("No.", '<>%1', '');
        PurchaseLine.SetRange(Quantity, 0);
        OnAfterSetPurchaseLineFilters(PurchaseLine, PurchaseHeader);

        if not PurchaseLine.IsEmpty() and GuiAllowed() then
            if MyNotifications.IsEnabled(PurchaseHeader.GetWarnWhenZeroQuantityPurchaseLinePosting()) then
                if Confirm(LinesMissingQuantityConfirmQst, false) then
                    exit
                else
                    Error('');
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetSalesLineFilters(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetPurchaseLineFilters(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchaseCheckAllLinesHaveQuantityAssigned(PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesCheckAllLinesHaveQuantityAssigned(SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;
}

