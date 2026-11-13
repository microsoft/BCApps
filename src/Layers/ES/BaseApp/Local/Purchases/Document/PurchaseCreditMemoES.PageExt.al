// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

#pragma warning disable AS0088
pageextension 10746 "Purchase Credit Memo ES" extends "Purchase Credit Memo"
{
    layout
    {
        addafter(General)
        {
            group(Payment)
            {
                Caption = 'Payment';
                Visible = false;
                ObsoleteState = Pending;
                ObsoleteReason = 'Standard fields are in General. The vendor bank account field is added by the Purchase Credit Memo ES page extension.';
                ObsoleteTag = '30.0';
            }
        }
        addafter("Expected Receipt Date")
        {
            field("Vendor Bank Acc. Code"; Rec."Vendor Bank Acc. Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the vendor bank code to assign to the purchase header in this field.';
            }
        }
        addafter("Format Region")
        {
            field("Correction Type"; Rec."Correction Type")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the Correction Type.';
            }
            field("Corrected Invoice No."; Rec."Corrected Invoice No.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the number of the posted invoice that you have corrected.';
            }
        }

    }

    actions
    {
        modify(CalculateInvoiceDiscount)
        {
            Caption = 'Calculate &Inv. and Pmt. Discounts';
            Image = CalculateDiscount;
            ToolTip = 'Update the lines with any payment discount that is specified in the related payment terms.';
        }
    }
}
