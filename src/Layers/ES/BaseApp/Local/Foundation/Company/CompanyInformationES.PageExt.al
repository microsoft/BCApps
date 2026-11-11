// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Company;

using Microsoft.Finance.ReceivablesPayables;

#pragma warning disable AS0088
pageextension 7000146 "Company Information ES" extends "Company Information"
{
    layout
    {
        addafter("Giro No.")
        {
            field("Payment Days Code"; Rec."Payment Days Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the payment day code that is used by the customer or vendor.';
            }
            field("Non-Paymt. Periods Code"; Rec."Non-Paymt. Periods Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the non-payment period code that is used by the customer or vendor.';
            }
        }
    }

    actions
    {
        addbefore("Responsibility Centers")
        {
            group("P&ayments")
            {
                Caption = 'P&ayments';
                Image = Payment;
                action("Payment Days")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payment Days';
                    Image = PaymentDays;
                    RunObject = Page "Payment Days";
                    RunPageLink = "Table Name" = const("Company Information"),
                                  Code = field("Payment Days Code");
                    ToolTip = 'View or edit the list of payment days that can be associated with a payment code.';
                }
                action("Non-Payment Periods")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Non-Payment Periods';
                    Image = PaymentPeriod;
                    RunObject = Page "Non-Payment Periods";
                    RunPageLink = "Table Name" = const("Company Information"),
                                  Code = field("Non-Paymt. Periods Code");
                    ToolTip = 'View or edit the periods for which payments will not be made.';
                }
            }
        }
    }
}
