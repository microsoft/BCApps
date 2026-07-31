// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Sales.Receivables;

pageextension 7000182 "CRT Sales Order" extends "Sales Order"
{
    layout
    {
        addafter(SalesDocCheckFactbox)
        {
            part(Control1903433807; "Cartera Receiv. Statistics FB")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = field("Sell-to Customer No.");
                Visible = true;
            }
            part(Control1903433607; "Cartera Fact. Statistics FB")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = field("Sell-to Customer No.");
                Visible = true;
            }
        }
    }
}
