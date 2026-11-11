// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

pageextension 10733 "Service Invoice ES" extends "Service Invoice"
{
    layout
    {
        addafter("Prices Including VAT")
        {
            field("VAT Registration No."; Rec."VAT Registration No.")
            {
                ApplicationArea = VAT;
                ToolTip = 'Specifies the customer''s VAT registration number.';
            }
        }
        addafter("Location Code")
        {
            field("Applies-to Doc. Type"; Rec."Applies-to Doc. Type")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the type of the posted document that this document or journal line will be applied to when you post, for example to register payment.';
            }
            field("Applies-to Doc. No."; Rec."Applies-to Doc. No.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the number of the posted document that this document or journal line will be applied to when you post, for example to register payment.';
            }
        }
        addafter("Foreign Trade")
        {
            group(Payment)
            {
                Caption = 'Payment';
                field("Cust. Bank Acc. Code"; Rec."Cust. Bank Acc. Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customer''s bank code that was on the sales credit memo.';
                }
            }
        }
    }

    actions
    {
        modify("Calculate Invoice Discount")
        {
            Caption = 'Calculate &Inv. and Pmt. Discounts';
            ToolTip = 'Update the lines with any payment discount that is specified in the related payment terms.';
        }
    }

}
