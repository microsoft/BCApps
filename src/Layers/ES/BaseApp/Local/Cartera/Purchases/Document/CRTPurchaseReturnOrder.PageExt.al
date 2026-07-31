// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Purchases.Payables;

pageextension 7000175 "CRT Purchase Return Order" extends "Purchase Return Order"
{
    layout
    {
        addafter(IncomingDocAttachFactBox)
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
