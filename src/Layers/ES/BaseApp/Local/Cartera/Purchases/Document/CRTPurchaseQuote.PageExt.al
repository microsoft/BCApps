// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Purchases.Payables;

pageextension 7000176 "CRT Purchase Quote" extends "Purchase Quote"
{
    layout
    {
        addafter(Control1904651607)
        {
            part(Control1903433907; "Cartera Payables Statistics FB")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = field("Pay-to Vendor No.");
                Visible = true;
            }
        }
    }
}
