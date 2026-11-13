// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

pageextension 7000087 "Blanket Purchase Order ES" extends "Blanket Purchase Order"
{
    layout
    {
#if not CLEAN30
        addafter("Invoice Details")
        {
            group(Payment)
            {
                Caption = 'Payment';
                Visible = false;
                ObsoleteState = Pending;
                ObsoleteReason = 'Standard fields are in Invoice Details. The vendor bank account field is added by the Blanket Purchase Order ES page extension.';
                ObsoleteTag = '30.0';
            }
        }
#endif
        addafter("Expected Receipt Date")
        {
            field("Vendor Bank Acc. Code"; Rec."Vendor Bank Acc. Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the vendor bank code to assign to the purchase header in this field.';
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
