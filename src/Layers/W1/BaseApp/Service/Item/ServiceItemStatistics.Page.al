// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Item;

page 5982 "Service Item Statistics"
{
    Caption = 'Service Item Statistics';
    Editable = false;
    LinksAllowed = false;
    PageType = Card;
    SourceTable = "Service Item";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                fixed(Control1903895201)
                {
                    ShowCaption = false;
                    group(Resources)
                    {
                        Caption = 'Resources';
                        field("OrderInvTotalPrice[1]"; OrderInvTotalPrice[1])
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Invoiced Amount';
                            ToolTip = 'Specifies the invoiced amount related to the particular service item.';
                        }
                        field("OrderUsageTotalPrice[1]"; OrderUsageTotalPrice[1])
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Usage (Amount)';
                            ToolTip = 'Specifies the usage amount for the specified service item.';
                        }
                        field("OrderUsageTotalCost[1]"; OrderUsageTotalCost[1])
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Cost Amount';
                            ToolTip = 'Specifies the cost amount of the service item.';
                        }
                        field("OrderUsageTotalQty[1]"; OrderUsageTotalQty[1])
                        {
                            ApplicationArea = Service;
                            Caption = 'Quantity';
                            DecimalPlaces = 1 : 1;
                            ToolTip = 'Specifies the quantity of all G/L account entries, costs, items and/or resource hours in the service order.';
                        }
                        field("OrderUsageTotalInvQty[1]"; OrderUsageTotalInvQty[1])
                        {
                            ApplicationArea = Service;
                            Caption = 'Quantity Invoiced';
                            DecimalPlaces = 1 : 1;
                            ToolTip = 'Specifies the quantity that has been invoiced for the specified service item.';
                        }
                        field("OrderUsageTotalConsQty[1]"; OrderUsageTotalConsQty[1])
                        {
                            ApplicationArea = Service;
                            Caption = 'Quantity Consumed';
                            DecimalPlaces = 1 : 1;
                            ToolTip = 'Specifies the quantity of the particular service item that has been consumed.';
                        }
                        field("OrderInvProfit[1]"; OrderInvProfit[1])
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Profit Amount';
                            ToolTip = 'Specifies the amount of profit for the specified service item.';
                        }
                        field("OrderInvProfitPct[1]"; OrderInvProfitPct[1])
                        {
                            ApplicationArea = Service;
                            Caption = 'Profit %';
                            DecimalPlaces = 1 : 1;
                            ToolTip = 'Specifies the Invoiced Amount, minus the Usage (Cost) x 100, divided by the Invoiced Amount.';
                        }
                    }
                    group(Items)
                    {
                        Caption = 'Items';
                        field("OrderInvTotalPrice[2]"; OrderInvTotalPrice[2])
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Invoiced Price';
                            ToolTip = 'Specifies the price that was invoiced for the service item.';
                        }
                        field("OrderUsageTotalPrice[2]"; OrderUsageTotalPrice[2])
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Total Price';
                            ToolTip = 'Specifies the total price for the specified service item.';
                        }
                        field("OrderUsageTotalCost[2]"; OrderUsageTotalCost[2])
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Total Cost';
                            ToolTip = 'Specifies the total cost for the specified service item.';
                        }
                        field("OrderUsageTotalQty[2]"; OrderUsageTotalQty[2])
                        {
                            ApplicationArea = Service;
                            Caption = 'Profit %';
                            DecimalPlaces = 1 : 1;
                            ToolTip = 'Specifies the Invoiced Amount, minus the Usage (Cost) x 100, divided by the Invoiced Amount.';
                        }
                        field("OrderUsageTotalInvQty[2]"; OrderUsageTotalInvQty[2])
                        {
                            ApplicationArea = Service;
                            Caption = 'Profit %';
                            DecimalPlaces = 1 : 1;
                            ToolTip = 'Specifies the Invoiced Amount, minus the Usage (Cost) x 100, divided by the Invoiced Amount.';
                        }
                        field("OrderUsageTotalConsQty[2]"; OrderUsageTotalConsQty[2])
                        {
                            ApplicationArea = Service;
                            Caption = 'Profit %';
                            DecimalPlaces = 1 : 1;
                            ToolTip = 'Specifies the Invoiced Amount, minus the Usage (Cost) x 100, divided by the Invoiced Amount.';
                        }
                        field("OrderInvProfit[2]"; OrderInvProfit[2])
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Profit';
                            ToolTip = 'Specifies the profit for the specified service item.';
                        }
                        field("OrderInvProfitPct[2]"; OrderInvProfitPct[2])
                        {
                            ApplicationArea = Service;
                            Caption = 'Profit %';
                            DecimalPlaces = 1 : 1;
                            ToolTip = 'Specifies the Invoiced Amount, minus the Usage (Cost) x 100, divided by the Invoiced Amount.';
                        }
                    }
                    group("Costs && G/L Accounts")
                    {
                        Caption = 'Costs && G/L Accounts';
                        field("OrderInvTotalPrice[3]"; OrderInvTotalPrice[3])
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Invoiced Price';
                            ToolTip = 'Specifies the price that was invoiced for the service item.';
                        }
                        field("OrderUsageTotalPrice[3]"; OrderUsageTotalPrice[3])
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Total Price';
                            ToolTip = 'Specifies the total price for the specified service item.';
                        }
                        field("OrderUsageTotalCost[3]"; OrderUsageTotalCost[3])
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Total Cost';
                            ToolTip = 'Specifies the total cost for the specified service item.';
                        }
                        field("OrderUsageTotalQty[3]"; OrderUsageTotalQty[3])
                        {
                            ApplicationArea = Service;
                            Caption = 'Profit %';
                            DecimalPlaces = 1 : 1;
                            ToolTip = 'Specifies the Invoiced Amount, minus the Usage (Cost) x 100, divided by the Invoiced Amount.';
                        }
                        field("OrderUsageTotalInvQty[3]"; OrderUsageTotalInvQty[3])
                        {
                            ApplicationArea = Service;
                            Caption = 'Profit %';
                            DecimalPlaces = 1 : 1;
                            ToolTip = 'Specifies the Invoiced Amount, minus the Usage (Cost) x 100, divided by the Invoiced Amount.';
                        }
                        field("OrderUsageTotalConsQty[3]"; OrderUsageTotalConsQty[3])
                        {
                            ApplicationArea = Service;
                            Caption = 'Profit %';
                            DecimalPlaces = 1 : 1;
                            ToolTip = 'Specifies the Invoiced Amount, minus the Usage (Cost) x 100, divided by the Invoiced Amount.';
                        }
                        field("OrderInvProfit[3]"; OrderInvProfit[3])
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Profit';
                            ToolTip = 'Specifies the profit for the specified service item.';
                        }
                        field("OrderInvProfitPct[3]"; OrderInvProfitPct[3])
                        {
                            ApplicationArea = Service;
                            Caption = 'Profit %';
                            DecimalPlaces = 1 : 1;
                            ToolTip = 'Specifies the Invoiced Amount, minus the Usage (Cost) x 100, divided by the Invoiced Amount.';
                        }
                    }
                    group("Service Contracts")
                    {
                        Caption = 'Service Contracts';
                        field("OrderInvTotalPrice[4]"; OrderInvTotalPrice[4])
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Invoiced Price';
                            ToolTip = 'Specifies the price that was invoiced for the service item.';
                        }
                        field("OrderUsageTotalPrice[4]"; OrderUsageTotalPrice[4])
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Total Price';
                            ToolTip = 'Specifies the total price for the specified service item.';
                        }
                        field("OrderUsageTotalCost[4]"; OrderUsageTotalCost[4])
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Total Cost';
                            ToolTip = 'Specifies the total cost for the specified service item.';
                        }
                        field("OrderUsageTotalQty[4]"; OrderUsageTotalQty[4])
                        {
                            ApplicationArea = Service;
                            Caption = 'Profit %';
                            DecimalPlaces = 1 : 1;
                            ToolTip = 'Specifies the Invoiced Amount, minus the Usage (Cost) x 100, divided by the Invoiced Amount.';
                        }
                        field("OrderUsageTotalInvQty[4]"; OrderUsageTotalInvQty[4])
                        {
                            ApplicationArea = Service;
                            Caption = 'Profit %';
                            DecimalPlaces = 1 : 1;
                            ToolTip = 'Specifies the Invoiced Amount, minus the Usage (Cost) x 100, divided by the Invoiced Amount.';
                        }
                        field("OrderUsageTotalConsQty[4]"; OrderUsageTotalConsQty[4])
                        {
                            ApplicationArea = Service;
                            Caption = 'Profit %';
                            DecimalPlaces = 1 : 1;
                            ToolTip = 'Specifies the Invoiced Amount, minus the Usage (Cost) x 100, divided by the Invoiced Amount.';
                        }
                        field("OrderInvProfit[4]"; OrderInvProfit[4])
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Profit';
                            ToolTip = 'Specifies the profit for the specified service item.';
                        }
                        field("OrderInvProfitPct[4]"; OrderInvProfitPct[4])
                        {
                            ApplicationArea = Service;
                            Caption = 'Profit %';
                            DecimalPlaces = 1 : 1;
                            ToolTip = 'Specifies the Invoiced Amount, minus the Usage (Cost) x 100, divided by the Invoiced Amount.';
                        }
                    }
                    group(Total)
                    {
                        Caption = 'Total';
                        field("OrderInvTotalPrice[5]"; OrderInvTotalPrice[5])
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Invoiced Price';
                            ToolTip = 'Specifies the price that was invoiced for the service item.';
                        }
                        field("OrderUsageTotalPrice[5]"; OrderUsageTotalPrice[5])
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Total Price';
                            ToolTip = 'Specifies the total price for the specified service item.';
                        }
                        field("OrderUsageTotalCost[5]"; OrderUsageTotalCost[5])
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Total Cost';
                            ToolTip = 'Specifies the total cost for the specified service item.';
                        }
                        field("OrderUsageTotalQty[5]"; OrderUsageTotalQty[5])
                        {
                            ApplicationArea = Service;
                            Caption = 'Profit %';
                            DecimalPlaces = 1 : 1;
                            ToolTip = 'Specifies the Invoiced Amount, minus the Usage (Cost) x 100, divided by the Invoiced Amount.';
                        }
                        field("OrderUsageTotalInvQty[5]"; OrderUsageTotalInvQty[5])
                        {
                            ApplicationArea = Service;
                            Caption = 'Profit %';
                            DecimalPlaces = 1 : 1;
                            ToolTip = 'Specifies the Invoiced Amount, minus the Usage (Cost) x 100, divided by the Invoiced Amount.';
                        }
                        field("OrderUsageTotalConsQty[5]"; OrderUsageTotalConsQty[5])
                        {
                            ApplicationArea = Service;
                            Caption = 'Profit %';
                            DecimalPlaces = 1 : 1;
                            ToolTip = 'Specifies the Invoiced Amount, minus the Usage (Cost) x 100, divided by the Invoiced Amount.';
                        }
                        field("OrderInvProfit[5]"; OrderInvProfit[5])
                        {
                            ApplicationArea = Service;
                            AutoFormatType = 1;
                            Caption = 'Profit';
                            ToolTip = 'Specifies the profit for the specified service item.';
                        }
                        field("OrderInvProfitPct[5]"; OrderInvProfitPct[5])
                        {
                            ApplicationArea = Service;
                            Caption = 'Profit %';
                            DecimalPlaces = 1 : 1;
                            ToolTip = 'Specifies the Invoiced Amount, minus the Usage (Cost) x 100, divided by the Invoiced Amount.';
                        }
                    }
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        ClearAll();

        for i := 1 to 4 do begin
            if i = Rec."Type Filter"::"Service Cost".AsInteger() then
                Rec.SetFilter("Type Filter", '%1|%2', Rec."Type Filter"::"Service Cost", Rec."Type Filter"::"G/L Account")
            else
                Rec.SetRange("Type Filter", i);
            Rec.CalcFields("Usage (Cost)", "Usage (Amount)", "Invoiced Amount", "Total Quantity", "Total Qty. Invoiced", "Total Qty. Consumed");

            if i = 4 then begin
                Rec.CalcFields("Contract Cost");
                OrderUsageTotalCost[i] := Rec."Contract Cost";
            end else
                OrderUsageTotalCost[i] := Rec."Usage (Cost)";
            OrderUsageTotalCost[5] := OrderUsageTotalCost[5] + Rec."Usage (Cost)";

            OrderUsageTotalPrice[i] := Rec."Usage (Amount)";
            OrderUsageTotalPrice[5] := OrderUsageTotalPrice[5] + Rec."Usage (Amount)";

            OrderInvTotalPrice[i] := Rec."Invoiced Amount";
            OrderInvTotalPrice[5] := OrderInvTotalPrice[5] + Rec."Invoiced Amount";

            OrderUsageTotalQty[i] := Rec."Total Quantity";
            OrderUsageTotalQty[5] := OrderUsageTotalQty[5] + Rec."Total Quantity";

            OrderUsageTotalInvQty[i] := Rec."Total Qty. Invoiced";
            OrderUsageTotalInvQty[5] := OrderUsageTotalInvQty[5] + Rec."Total Qty. Invoiced";

            OrderUsageTotalConsQty[i] := Rec."Total Qty. Consumed";
            OrderUsageTotalConsQty[5] := OrderUsageTotalConsQty[5] + Rec."Total Qty. Consumed";
        end;

        for i := 1 to 5 do begin
            OrderInvProfit[i] := OrderInvTotalPrice[i] - OrderUsageTotalCost[i];
            if OrderInvTotalPrice[i] <> 0 then
                OrderInvProfitPct[i] := CalcPercentage(OrderInvProfit[i], OrderInvTotalPrice[i])
            else
                OrderInvProfitPct[i] := 0;
        end;

        Rec.SetRange("Type Filter");
    end;

    var
        i: Integer;
        OrderUsageTotalCost: array[5] of Decimal;
        OrderUsageTotalPrice: array[5] of Decimal;
        OrderInvTotalPrice: array[5] of Decimal;
        OrderInvProfit: array[5] of Decimal;
        OrderInvProfitPct: array[5] of Decimal;
        OrderUsageTotalQty: array[5] of Decimal;
        OrderUsageTotalInvQty: array[5] of Decimal;
        OrderUsageTotalConsQty: array[5] of Decimal;

    local procedure CalcPercentage(PartAmount: Decimal; Base: Decimal): Decimal
    begin
        if Base <> 0 then
            exit(100 * PartAmount / Base);
        exit(0);
    end;
}

