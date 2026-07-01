// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Sales.Receivables;

pageextension 7000181 "CRT Sales Quote" extends "Sales Quote"
{
    layout
    {
        addfirst(Factboxes)
        {
            part(Control1903433807; "Cartera Receiv. Statistics FB")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = field("Bill-to Customer No.");
                Visible = true;
            }
            part(Control1903433607; "Cartera Fact. Statistics FB")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = field("Bill-to Customer No.");
                Visible = true;
            }
        }
    }
}
