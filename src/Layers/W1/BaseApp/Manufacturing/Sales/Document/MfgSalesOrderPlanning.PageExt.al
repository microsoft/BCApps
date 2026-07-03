// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Wizard;

pageextension 99000883 "Mfg. Sales Order Planning" extends "Sales Order Planning"
{
    actions
    {
        addafter("Update &Shipment Dates")
        {
            action("&Create Prod. Order")
            {
                AccessByPermission = TableData "Production Order" = R;
                ApplicationArea = Manufacturing;
                Caption = '&Create Prod. Order';
                Image = CreateDocument;
                ToolTip = 'Prepare to create a production order to fulfill the sales demand.';

                trigger OnAction()
                begin
                    CreateProdOrder();
                end;
            }
        }
        addafter("Update &Shipment Dates_Promoted")
        {
            actionref("&Create Prod. Order_Promoted"; "&Create Prod. Order")
            {
            }
        }
    }

    var
        NewStatus: Enum "Production Order Status";
        NewOrderType: Enum "Create Production Order Type";
        UseWizard: Boolean;

        Text001: Label 'There is nothing to plan.';

    procedure CreateProdOrder()
    var
        CreateOrderFromSales: Page "Create Order From Sales";
        TempSalesPlanningLine: Record "Sales Planning Line" temporary;
        NewOrderTypeOption: Option;
        ShowCreateOrderForm: Boolean;
        IsHandled: Boolean;
        SalesPlanningCount: Integer;
    begin
        UseWizard := false;
        ShowCreateOrderForm := true;
        IsHandled := false;
        NewOrderTypeOption := NewOrderType.AsInteger();
        TempSalesPlanningLine.Copy(Rec, true);
        CurrPage.SetSelectionFilter(TempSalesPlanningLine);

        OnBeforeCreateProdOrder(TempSalesPlanningLine, NewStatus, NewOrderTypeOption, ShowCreateOrderForm, IsHandled);
        NewOrderType := "Create Production Order Type".FromInteger(NewOrderTypeOption);
        if IsHandled then
            exit;

        if ShowCreateOrderForm then begin
            CreateOrderFromSales.SetSingleLineSelected(TempSalesPlanningLine.Count() = 1);
            if CreateOrderFromSales.RunModal() <> ACTION::Yes then
                exit;

            CreateOrderFromSales.GetParameters(NewStatus, NewOrderType);
            UseWizard := CreateOrderFromSales.GetUseProductDefinitionWizard();
            OnCreateProdOrderOnAfterGetParameters(TempSalesPlanningLine, NewStatus, NewOrderType);
            Clear(CreateOrderFromSales);
        end;

        if not CreateOrders(TempSalesPlanningLine) then
            Message(Text001);

        Rec.SetRange("Planning Status");

        BuildForm();

        OnAfterCreateProdOrder(Rec);

        CurrPage.Update(false);
    end;

    local procedure CreateOrders(var TempSalesPlanningLine: Record "Sales Planning Line" temporary) OrdersCreated: Boolean
    var
        xSalesPlanLine: Record "Sales Planning Line";
        SalesLine: Record "Sales Line";
        CreateProdOrderLines: Codeunit "Create Prod. Order Lines";
        DoCreateProdOrder: Boolean;
        EndLoop: Boolean;
        IsHandled: Boolean;
        ProcessOrder: Boolean;
    begin
        xSalesPlanLine := TempSalesPlanningLine;

        OrdersCreated := false;
        OnCreateOrdersOnBeforeFindSet(TempSalesPlanningLine, IsHandled, OrdersCreated);
        if IsHandled then
            exit;

        if not TempSalesPlanningLine.FindSet() then
            exit;

        repeat
            SalesLine.Get(SalesLine."Document Type"::Order, TempSalesPlanningLine."Sales Order No.", TempSalesPlanningLine."Sales Order Line No.");
            SalesLine.TestField("Shipment Date");
            SalesLine.CalcFields("Reserved Qty. (Base)");

            IsHandled := false;
            ProcessOrder := true;
            OnCreateOrdersOnBeforeCreateProdOrder(TempSalesPlanningLine, SalesLine, IsHandled, ProcessOrder, OrdersCreated, EndLoop);
            if IsHandled then
                exit;

            if ProcessOrder then
                if SalesLine."Outstanding Qty. (Base)" > SalesLine."Reserved Qty. (Base)" then begin
                    DoCreateProdOrder := CreateProdOrderLines.CheckReplenishmentSystemProdOrderAndNotProductionBlocked(SalesLine."No.", SalesLine."Variant Code", SalesLine."Location Code");

                    CreateOrder(TempSalesPlanningLine, DoCreateProdOrder, SalesLine, EndLoop, OrdersCreated);
                end;
        until (TempSalesPlanningLine.Next() = 0) or EndLoop;

        TempSalesPlanningLine := xSalesPlanLine;
    end;

    local procedure CreateOrder(var TempSalesPlanningLine: Record "Sales Planning Line" temporary; DoCreateProdOrder: Boolean; var SalesLine: Record "Sales Line"; var EndLoop: Boolean; var OrdersCreated: Boolean)
    var
        ProductionDefinitionManager: Codeunit "Production Definition Manager";
        CreateProdOrderFromSale: Codeunit "Create Prod. Order from Sale";
        HideValidationDialog: Boolean;
    begin
        HideValidationDialog := false;
        OnBeforeCreateOrder(TempSalesPlanningLine, SalesLine, DoCreateProdOrder, HideValidationDialog);

        if DoCreateProdOrder then begin
            if UseWizard then begin
                if ProductionDefinitionManager.RunForSource(SalesLine, "Prod. Definition Mode"::CreateProductionOrder, NewStatus) then
                    OrdersCreated := true;
            end else begin
                OrdersCreated := true;
                CreateProdOrderFromSale.SetHideValidationDialog(HideValidationDialog);
                CreateProdOrderFromSale.CreateProductionOrder(SalesLine, NewStatus, NewOrderType);
                if NewOrderType = NewOrderType::ProjectOrder then
                    EndLoop := true;
            end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateProdOrder(var SalesPlanningLine: Record "Sales Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateProdOrder(var SalesPlanningLine: Record "Sales Planning Line"; var NewStatus: Enum "Production Order Status"; var NewOrderType: Option ItemOrder,ProjectOrder; var ShowCreateOrderForm: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateProdOrderOnAfterGetParameters(var SalesPlanningLine: Record "Sales Planning Line"; var NewStatus: Enum "Production Order Status"; var NewOrderType: Enum "Create Production Order Type")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCreateOrdersOnBeforeFindSet(var SalesPlanningLine: Record "Sales Planning Line"; var IsHandled: Boolean; var OrdersCreated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateOrdersOnBeforeCreateProdOrder(var SalesPlanningLine: Record "Sales Planning Line"; var SalesLine: Record "Sales Line"; var IsHandled: Boolean; var ProcessOrder: Boolean; var OrdersCreated: Boolean; var EndLoop: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateOrder(var SalesPlanningLine: Record "Sales Planning Line"; var SalesLine: Record "Sales Line"; var CreateProdOrder: Boolean; var HideValidationDialog: Boolean);
    begin
    end;

}
