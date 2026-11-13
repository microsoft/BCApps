// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

pageextension 7000078 "Purchase Invoice ES" extends "Purchase Invoice"
{
    layout
    {
        addafter("On Hold")
        {
            field("Vendor Bank Acc. Code"; Rec."Vendor Bank Acc. Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the vendor bank code to assign to the purchase header in this field.';
            }
            group(Payment)
            {
                Caption = 'Payment';
                Visible = false;
                ObsoleteState = Pending;
                ObsoleteReason = 'The vendor bank account field is added by the Purchase Invoice ES page extension.';
                ObsoleteTag = '30.0';
            }
        }
        modify("Payment Terms Code")
        {
            ShowMandatory = true;
        }
        modify("Payment Method Code")
        {
            ShowMandatory = true;
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
