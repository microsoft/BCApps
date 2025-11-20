// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

codeunit 84 "Blnkt Sales Ord. to Ord. (Y/N)"
{
    TableNo = "Sales Header";

    trigger OnRun()
    var
        SkipMessage: Boolean;
    begin
        if IsOnRunHandled(Rec) then
            exit;

        Rec.TestField("Document Type", Rec."Document Type"::"Blanket Order");
        if ShouldExit(Rec) then
            exit;

        BlanketSalesOrderToOrder.Run(Rec);
        BlanketSalesOrderToOrder.GetSalesOrderHeader(SalesOrderHeader);

        OnAfterCreateSalesOrder(SalesOrderHeader, SkipMessage);
        if not SkipMessage then
            Message(OrderCreatedMsg, SalesOrderHeader."No.", Rec."No.");
    end;

    var
        SalesOrderHeader: Record "Sales Header";
        BlanketSalesOrderToOrder: Codeunit "Blanket Sales Order to Order";

        CreateConfirmQst: Label 'Do you want to create an order from the blanket order?';
        OrderCreatedMsg: Label 'Order %1 has been created from blanket order %2.', Comment = '%1 = Order No., %2 = Blanket Order No.';

    local procedure IsOnRunHandled(var SalesHeader: Record "Sales Header") IsHandled: Boolean
    begin
        IsHandled := false;
        OnBeforeRun(SalesHeader, IsHandled);
        exit(IsHandled);
    end;

    local procedure ShouldExit(var SalesHeader: Record "Sales Header") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShouldExit(SalesHeader, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if GuiAllowed then
            if not Confirm(CreateConfirmQst, false) then
                Result := true;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateSalesOrder(var SalesHeader: Record "Sales Header"; var SkipMessage: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRun(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShouldExit(var SalesHeader: Record "Sales Header"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
}

