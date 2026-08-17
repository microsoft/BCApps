// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CashFlow.Forecast;

pageextension 6480 "Serv. Cash Flow Avail. Lines" extends "Cash Flow Availability Lines"
{
    layout
    {
        addafter("SalesOrders")
        {
            field(ServiceOrders; Rec."Service Orders")
            {
                ApplicationArea = Service;
                AutoFormatExpression = FormatStr();
                AutoFormatType = 11;
                Caption = 'Service Orders';
                ToolTip = 'Specifies amounts related to service orders.';

                trigger OnDrillDown()
                begin
                    CashFlowForecast.DrillDownSourceTypeEntries(CashFlowForecast."Source Type Filter"::"Service Orders");
                end;
            }
        }
    }
}
