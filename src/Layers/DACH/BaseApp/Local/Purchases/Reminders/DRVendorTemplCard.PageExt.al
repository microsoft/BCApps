// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

pageextension 5005271 DRVendorTemplCard extends "Vendor Templ. Card"
{
    layout
    {
        addafter("Over-Receipt Code")
        {
            field("Delivery Reminder Terms"; Rec."Delivery Reminder Terms")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the delivery reminder terms code for the vendor.';
            }
        }
    }
}
