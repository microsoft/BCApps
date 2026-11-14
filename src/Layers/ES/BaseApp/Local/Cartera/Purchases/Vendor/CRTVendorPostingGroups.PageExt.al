// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

pageextension 7000076 "CRT Vendor Posting Groups" extends "Vendor Posting Groups"
{
    layout
    {
        addafter("Credit Rounding Account")
        {
            field("Bills Account"; Rec."Bills Account")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the account where the payable bills generated from a purchase invoice will be entered.';
            }
            field("Bills in Payment Order Acc."; Rec."Bills in Payment Order Acc.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the account where the payable bills will be entered, when they are posted to a payment order.';
            }
            field("Invoices in  Pmt. Ord. Acc."; Rec."Invoices in  Pmt. Ord. Acc.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the account where the purchase invoices will be entered, when they are posted to a payment order.';
            }
        }
    }
}
