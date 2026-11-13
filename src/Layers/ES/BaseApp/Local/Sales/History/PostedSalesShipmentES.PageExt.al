// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

pageextension 7000094 "Posted Sales Shipment ES" extends "Posted Sales Shipment"
{
    layout
    {
        addafter("Shipment Date")
        {
            field("Cust. Bank Acc. Code"; Rec."Cust. Bank Acc. Code")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                ToolTip = 'Specifies the client''s bank code that was in the header, on the order from which this sales receipt was created.';
            }
        }
        addafter(Shipping)
        {
            group(Payment)
            {
                Caption = 'Payment';
                Visible = false;
                ObsoleteState = Pending;
                ObsoleteReason = 'The customer bank account field is added by the Posted Sales Shipment ES page extension.';
                ObsoleteTag = '30.0';
            }
        }
    }
}
