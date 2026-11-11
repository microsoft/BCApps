// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

using Microsoft.Finance.ReceivablesPayables;

#pragma warning disable AS0088
pageextension 7000140 "Customer Card ES" extends "Customer Card"
{
    layout
    {
        addafter("Payment Method Code")
        {
            field("Payment Days Code"; Rec."Payment Days Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the payment days code used by this customer.';
            }
            field("Non-Paymt. Periods Code"; Rec."Non-Paymt. Periods Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the non-payment period code used by this customer.';
            }
        }
    }

    actions
    {
        addafter("Co&mments")
        {
            action("&Payment Days")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Payment Days';
                Image = PaymentDays;
                RunObject = Page "Payment Days";
                RunPageLink = "Table Name" = const(Customer),
                              Code = field("Payment Days Code");
                ToolTip = 'View or edit the payment days that are associated with the payment code.';
            }
            action("N&on-Payment Periods")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'N&on-Payment Periods';
                Image = PaymentPeriod;
                RunObject = Page "Non-Payment Periods";
                RunPageLink = "Table Name" = const(Customer),
                              Code = field("Non-Paymt. Periods Code");
                ToolTip = 'View or edit the periods for which payments will not be made.';
            }
        }
    }
}
