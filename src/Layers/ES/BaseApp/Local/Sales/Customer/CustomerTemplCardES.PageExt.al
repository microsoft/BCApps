// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

#pragma warning disable AS0088
pageextension 7000142 "Customer Template Card ES" extends "Customer Templ. Card"
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
}
