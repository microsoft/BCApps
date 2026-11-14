// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

#pragma warning disable AS0088
pageextension 10758 "Vendor Template Card ES" extends "Vendor Templ. Card"
{
    layout
    {
        addafter("Payment Method Code")
        {
            field("Payment Days Code"; Rec."Payment Days Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the payment day code used by this vendor.';
            }
            field("Non-Paymt. Periods Code"; Rec."Non-Paymt. Periods Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the non-payment day code used by this vendor.';
            }
        }
    }
}
