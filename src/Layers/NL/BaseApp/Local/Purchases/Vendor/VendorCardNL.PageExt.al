// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

pageextension 11301 VendorCardNL extends "Vendor Card"
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
        addafter(City)
        {
#if not CLEAN29
            group(Control198)
            {
                ObsoleteReason = 'Replaced by Control1199';
                ObsoleteState = Pending;
                ObsoleteTag = '29.0';
            }
#endif
        }
        modify("EORI Number")
        {
            Visible = true;
        }
    }
}
