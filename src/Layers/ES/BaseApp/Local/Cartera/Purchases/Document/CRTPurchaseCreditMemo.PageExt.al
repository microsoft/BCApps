// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Purchases.Payables;

pageextension 7000172 "CRT Purchase Credit Memo" extends "Purchase Credit Memo"
{
    layout
    {
        addafter("Applies-to Doc. No.")
        {
            field("Applies-to Bill No."; Rec."Applies-to Bill No.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies if you want to settle an open payable bill with a credit memo from a vendor.';
            }
        }
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
