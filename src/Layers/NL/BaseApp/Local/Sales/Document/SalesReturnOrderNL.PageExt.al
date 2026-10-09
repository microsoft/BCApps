// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

/// <summary>
/// Extends the Sales Return Order page with NL-specific telebanking fields.
/// </summary>
pageextension 11469 "Sales Return Order NL" extends "Sales Return Order"
{
    layout
    {
        addafter("Payment Method Code")
        {
            field("Transaction Mode Code"; Rec."Transaction Mode Code")
            {
                ApplicationArea = SalesReturnOrder;
                ToolTip = 'Specifies the transaction mode used in telebanking.';
            }
            field("Bank Account Code"; Rec."Bank Account Code")
            {
                ApplicationArea = SalesReturnOrder;
                ToolTip = 'Specifies the customer''s bank account that is used for payments and collections through telebanking.';
            }
        }
    }
}
