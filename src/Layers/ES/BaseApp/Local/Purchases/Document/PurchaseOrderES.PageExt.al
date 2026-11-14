// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

pageextension 7000079 "Purchase Order ES" extends "Purchase Order"
{
    layout
    {
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
            ToolTip = 'Update the lines with any payment discount that is specified in the related payment terms.';
        }
    }
}
