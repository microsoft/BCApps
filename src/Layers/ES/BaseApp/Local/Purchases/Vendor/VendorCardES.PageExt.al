// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

using Microsoft.Finance.ReceivablesPayables;

#pragma warning disable AS0088
pageextension 10756 "Vendor Card ES" extends "Vendor Card"
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

    actions
    {
        addafter("Co&mments")
        {
            action("P&ayment Days")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'P&ayment Days';
                Image = PaymentDays;
                RunObject = Page "Payment Days";
                RunPageLink = "Table Name" = const(Vendor),
                              Code = field("Payment Days Code");
                ToolTip = 'View or edit the payment days that are associated with the payment code.';
            }
            action("Non-Pa&yment Periods")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Non-Pa&yment Periods';
                Image = PaymentPeriod;
                RunObject = Page "Non-Payment Periods";
                RunPageLink = "Table Name" = const(Vendor),
                              Code = field("Non-Paymt. Periods Code");
                ToolTip = 'View or edit the periods for which payments will not be made.';
            }
        }
    }
}
