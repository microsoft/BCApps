// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

pageextension 10735 "Service Credit Memo ES" extends "Service Credit Memo"
{
    layout
    {
        addafter("Your Reference")
        {
            field("Corrected Invoice No."; Rec."Corrected Invoice No.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the number of the posted invoice that you need to correct.';
            }
        }
        addafter("Prices Including VAT")
        {
            field("VAT Registration No."; Rec."VAT Registration No.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the customer''s VAT registration number.';
            }
        }
        addafter(Application)
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
