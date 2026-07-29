// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

pageextension 11305 VendorTemplCardNL extends "Vendor Templ. Card"
{
    layout
    {
        addafter("Payment Terms Code")
        {
            field("Transaction Mode Code"; Rec."Transaction Mode Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the transaction mode used in telebanking.';
            }
        }
    }
}
