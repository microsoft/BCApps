// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.SalesFR;

using Microsoft.Sales.History;

pageextension 10808 "Posted Sales Invoice" extends "Posted Sales Invoice"
{
    layout
    {
        addafter("Payment Method Code")
        {
            field("VAT Paid on Debits FR"; Rec."VAT Paid on Debits FR")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                ToolTip = 'Specifies if the VAT was paid on debits for this document.';
            }
        }
    }
}
