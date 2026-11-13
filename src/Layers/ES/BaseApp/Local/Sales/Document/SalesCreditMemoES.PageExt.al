// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

#pragma warning disable AS0088
pageextension 10744 "Sales Credit Memo ES" extends "Sales Credit Memo"
{
    layout
    {
#if not CLEAN30
        addafter("Credit Memo Details")
        {
            group(Payment)
            {
                Caption = 'Payment';
                Visible = false;
                ObsoleteState = Pending;
                ObsoleteReason = 'Standard fields are in Credit Memo Details. The customer bank account field is added by the Sales Credit Memo ES page extension.';
                ObsoleteTag = '30.0';
            }
        }
#endif
        addafter("Shipment Date")
        {
            field("Cust. Bank Acc. Code"; Rec."Cust. Bank Acc. Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the customer bank code to assign to the sales header in this field.';
            }
        }
        addafter(Status)
        {
            field("Correction Type"; Rec."Correction Type")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the Correction Type.';
            }
            field("Corrected Invoice No."; Rec."Corrected Invoice No.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the number of the posted invoice that you need to correct.';
            }
        }

    }

    actions
    {
        modify(CalculateInvoiceDiscount)
        {
            Caption = 'Calculate &Inv. and Pmt. Discounts';
            ToolTip = 'Update the lines with any payment discount that is specified in the related payment terms.';
        }
    }
}
