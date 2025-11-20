// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CashFlow.Forecast;

using Microsoft.CashFlow.Setup;

pageextension 6481 "Serv. Cash Flow Forecast Stat." extends "Cash Flow Forecast Statistics"
{
    layout
    {
        addafter(SalesOrders)
        {
            field(ServiceOrders; Rec.CalcSourceTypeAmount("Cash Flow Source Type"::"Service Orders"))
            {
                ApplicationArea = Service;
                Caption = 'Service Orders';
                ToolTip = 'Specifies amounts related to service orders.';

                trigger OnDrillDown()
                begin
                    Rec.DrillDownSourceTypeEntries("Cash Flow Source Type"::"Service Orders");
                end;
            }
        }
    }
}
