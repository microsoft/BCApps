// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CashFlow.Forecast;

using Microsoft.CashFlow.Setup;

pageextension 6482 "Serv. CFForecastStatFactBox" extends "CF Forecast Statistics FactBox"
{
    layout
    {
        addafter(SalesOrders)
        {
            field(ServiceOrders; Rec.CalcSourceTypeAmount("Cash Flow Source Type"::"Service Orders"))
            {
                ApplicationArea = Service;
                Caption = 'Service Orders';
                ToolTip = 'Specifies the amount of the service order to be received and paid out by your business for the cash flow forecast.';

                trigger OnDrillDown()
                begin
                    Rec.DrillDownSourceTypeEntries("Cash Flow Source Type"::"Service Orders");
                end;
            }

        }
    }
}
