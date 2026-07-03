// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

using Microsoft.Purchases.Payables;

pageextension 7000193 "CRT Vendor List" extends "Vendor List"
{
    layout
    {
        addafter(VendorHistPayToFactBox)
        {
            part(Control1903433907; "Cartera Payables Statistics FB")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = field("No.");
                Visible = true;
            }
        }
    }
}
