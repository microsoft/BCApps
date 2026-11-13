// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

#pragma warning disable AS0088
pageextension 10748 "Posted Sales Credit Memo ES" extends "Posted Sales Credit Memo"
{
    layout
    {
        addbefore("Applies-to Doc. Type")
        {
            field("Cust. Bank Acc. Code"; Rec."Cust. Bank Acc. Code")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                ToolTip = 'Specifies the customer''s bank code that was on the sales header when this credit memo was issued.';
            }
        }
#if not CLEAN30
        addafter("Invoice Details")
        {
            group(Payment)
            {
                Caption = 'Payment';
                Visible = false;
                ObsoleteState = Pending;
                ObsoleteReason = 'Standard fields are in Invoice Details. The customer bank account field is added by the Posted Sales Credit Memo ES page extension.';
                ObsoleteTag = '30.0';
            }
        }
#endif
        addafter("Work Description")
        {
            field("Correction Type"; Rec."Correction Type")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                ToolTip = 'Specifies the Correction Type.';
            }
            field("Corrected Invoice No."; Rec."Corrected Invoice No.")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                ToolTip = 'Specifies the number of the posted invoice that you need to correct.';
            }
        }
    }
}
