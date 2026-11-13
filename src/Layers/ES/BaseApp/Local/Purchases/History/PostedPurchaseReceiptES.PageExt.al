// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

pageextension 7000093 "Posted Purchase Receipt ES" extends "Posted Purchase Receipt"
{
    layout
    {
        addafter("Expected Receipt Date")
        {
            field("Vendor Bank Acc. Code"; Rec."Vendor Bank Acc. Code")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                ToolTip = 'Specifies the customer''s bank code that is in the header on the order from which this purchase receipt was created.';
            }
        }
#if not CLEAN30
        addafter(Shipping)
        {
            group(Payment)
            {
                Caption = 'Payment';
                Visible = false;
                ObsoleteState = Pending;
                ObsoleteReason = 'The vendor bank account field is added by the Posted Purchase Receipt ES page extension.';
                ObsoleteTag = '30.0';
            }
        }
#endif
    }
}
