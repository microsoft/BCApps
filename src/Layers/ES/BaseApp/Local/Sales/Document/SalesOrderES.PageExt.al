// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

pageextension 7000090 "Sales Order ES" extends "Sales Order"
{
    layout
    {
        addafter("Invoice Details")
        {
            group(Payment)
            {
                Caption = 'Payment';
                Visible = false;
                ObsoleteState = Pending;
                ObsoleteReason = 'The customer bank account field is added by the Sales Order ES page extension.';
                ObsoleteTag = '30.0';
            }
        }
        addafter("Direct Debit Mandate ID")
        {
            field("Cust. Bank Acc. Code"; Rec."Cust. Bank Acc. Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the customer bank code to assign to the sales header in this field.';
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
